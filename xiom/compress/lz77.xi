// XIOM - Compression: LZ77
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.compress.lz77

// Depends on: xiom.string

// ============================================================================
// LZ77 sliding-window compression.
//
// Token stream (control-byte scheme, documented and round-trip safe):
//   literal run: ctrl byte with bit 7 clear; count = (ctrl & 0x7F) + 1;
//                `count` literal bytes follow (1..128).
//   match:       ctrl byte with bit 7 set; length = (ctrl & 0x7F) + 3
//                (3..130); then 2 little-endian bytes for the back distance
//                (1..65535). The match copies from the already-emitted output
//                and supports overlapping copies (e.g. "aaaa" patterns).
//
// lz77_find_longest_match / lz77_token_encode / lz77_token_decode expose the
// search and packing primitives. Round-trip correctness within XIOM is the
// goal; this stream is NOT wire-compatible with zlib's LZ77 (documented).
// Compress complexity: O(n * window), n = data length.
// ============================================================================

/// Compress `data` with a greedy 32KiB sliding-window search into the
/// control-byte token stream documented above. O(n * 32768).
pub fn lz77_compress(data: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var len = data.len();
  if len == 0 {
    return result;
  };
  var pos = 0;
  while pos < len {
    var best_len = 0;
    var best_off = 0;
    var search_start = pos - 32768;
    if search_start < 0 {
      search_start = 0;
    };
    var si = search_start;
    while si < pos {
      var match_len = 0;
      while (si + match_len) < pos && (pos + match_len) < len && match_len < 258 {
        var a = data[si + match_len];
        var b = data[pos + match_len];
        if a != b {
          break;
        };
        match_len = match_len + 1;
      }
      if match_len > best_len && match_len >= 3 {
        best_len = match_len;
        best_off = pos - si;
      };
      si = si + 1;
    }
    if best_len >= 3 && best_off <= 65535 {
      var mlen = best_len;
      if mlen > 130 {
        mlen = 130;
      };
      var ctrl = ((mlen - 3) | 0x80) as Int;
      result.push(ctrl as UInt8);
      result.push((best_off & 0xFF) as UInt8);
      result.push(((best_off >> 8) & 0xFF) as UInt8);
      pos = pos + mlen;
    } else {
      result.push(0 as UInt8);
      result.push(data[pos]);
      pos = pos + 1;
    };
  }
  return result;
}

/// Decompress an lz77_compress token stream. Returns Err on truncated input,
/// a zero match distance, or a distance beyond the emitted output.
// Default output ceiling for uncapped decompression (1 GiB): bounds
// decompression-bomb amplification while never triggering for legitimate
// stdlib-roundtrip data. Capped variants accept an explicit limit.
const _LZ77_DEFAULT_CAP: Int = 1073741824;

pub fn lz77_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] {
  return lz77_decompress_capped(data, _LZ77_DEFAULT_CAP);
}

/// Decompress with a hard ceiling on output size. Every expansion step is
/// checked BEFORE writing, so a hostile token stream cannot allocate beyond
/// the cap even momentarily. Returns Err("lz77: output exceeds cap") when
/// exceeded.
pub fn lz77_decompress_capped(data: &Vec[UInt8], max_out: Int) -> Result[Vec[UInt8], Str] {
  var result = Vec[UInt8].new();
  var len = data.len();
  var pos = 0;
  while pos < len {
    var ctrl_b = data[pos];
    var ctrl = ctrl_b as Int;
    pos = pos + 1;
    if (ctrl & 0x80) == 0 {
      var count = (ctrl & 0x7F) + 1;
      if pos + count > len {
        return Err("lz77: truncated literal run");
      };
      if result.len() + count > max_out {
        return Err("lz77: output exceeds cap");
      };
      var k = 0;
      while k < count {
        result.push(data[pos + k]);
        k = k + 1;
      }
      pos = pos + count;
    } else {
      var mlen = (ctrl & 0x7F) + 3;
      if pos + 2 > len {
        return Err("lz77: truncated match");
      };
      var o0 = data[pos] as Int;
      var o1 = data[pos + 1] as Int;
      var off = o0 | (o1 << 8);
      pos = pos + 2;
      if off == 0 {
        return Err("lz77: zero match distance");
      };
      var dst_len = result.len();
      if off > dst_len {
        return Err("lz77: match distance exceeds output length");
      };
      if dst_len + mlen > max_out {
        return Err("lz77: output exceeds cap");
      };
      var k2 = 0;
      while k2 < mlen {
        var src_idx = dst_len - off + (k2 % off);
        result.push(result[src_idx]);
        k2 = k2 + 1;
      }
    }
  }
  return Ok(result);
}

/// Locate the longest match for the byte at `pos` searching back at most
/// `window` positions. Returns (length, distance); (0, 0) when no match of
/// length >= 3 exists. Out-of-range positions yield (0, 0).
/// Complexity: O(window * match_length).
pub fn lz77_find_longest_match(data: &Vec[UInt8], pos: Int, window: Int) -> (Int, Int) {
  var len = data.len();
  if pos < 0 || pos >= len {
    return (0, 0);
  };
  var win = window;
  if win < 0 {
    win = 0;
  };
  var best_len = 0;
  var best_off = 0;
  var search_start = pos - win;
  if search_start < 0 {
    search_start = 0;
  };
  var si = search_start;
  while si < pos {
    var match_len = 0;
    while (si + match_len) < pos && (pos + match_len) < len && match_len < 258 {
      var a = data[si + match_len];
      var b = data[pos + match_len];
      if a != b {
        break;
      };
      match_len = match_len + 1;
    }
    if match_len > best_len && match_len >= 3 {
      best_len = match_len;
      best_off = pos - si;
    };
    si = si + 1;
  }
  return (best_len, best_off);
}

/// Pack a (length, distance) pair into a single token: (length << 16) | distance.
/// Both fields are clamped to 16 bits (0..65535). Pure-Int token.
pub fn lz77_token_encode(length: Int, distance: Int) -> Int {
  var l = length;
  if l < 0 {
    l = 0;
  };
  if l > 65535 {
    l = 65535;
  };
  var d = distance;
  if d < 0 {
    d = 0;
  };
  if d > 65535 {
    d = 65535;
  };
  return (l << 16) | d;
}

/// Unpack a token produced by lz77_token_encode into (length, distance).
pub fn lz77_token_decode(token: Int) -> (Int, Int) {
  var length = (token >> 16) & 0xFFFF;
  var distance = token & 0xFFFF;
  return (length, distance);
}
