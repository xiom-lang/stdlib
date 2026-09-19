// XIOM - Compression: Snappy
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.compress.snappy

// Depends on: xiom.string

// ============================================================================
// Snappy-style raw-stream and framed compression.
//
// Raw stream: varint(uncompressed length) + compressed elements.
// Elements (type = low 2 bits of the tag byte):
//   00 literal  length = (tag >> 2) + 1 when < 60, otherwise 60..63 selects
//               1..4 little-endian bytes holding (length - 1).
//   01 copy1    offset = ((tag >> 5) << 8) | next byte; length = ((tag >> 2) & 7) + 4.
//   10 copy2    offset = 16-bit LE after the tag; length = next byte + 1.
//   11          reserved -> Err.
// The encoder emits literals and copy2 elements (matches need length >= 4).
//
// snappy_compress / snappy_decompress are the raw stream; snappy_compress_frame
// wraps it with an outer varint of the compressed payload length so the frame
// is self-delimiting. Round-trip correctness within XIOM is the goal; the
// element layout follows the documented Snappy algorithm but is NOT verified
// byte-for-byte against the C library. Complexity: O(n * window).
// ============================================================================

/// Append a non-negative Int as an LEB128 varint (7 bits per byte, high bit
/// set on continuation bytes).
fn _put_varint(out: &mut Vec[UInt8], v: Int) {
  var x = v;
  if x < 0 {
    x = 0;
  };
  while x >= 128 {
    var low = x & 0x7F;
    out.push((low | 0x80) as UInt8);
    x = x >> 7;
  }
  out.push(x as UInt8);
}

/// Read an LEB128 varint from `start`. Returns (value, bytes_consumed) or
/// (-1, -1) when malformed (truncated, overlong, or negative overflow).
fn _get_varint(data: &Vec[UInt8], start: Int) -> (Int, Int) {
  var result_val = 0;
  var shift = 0;
  var pos = start;
  var len = data.len();
  while pos < len && shift <= 56 {
    var b = data[pos];
    var bv = b as Int;
    result_val = result_val | ((bv & 0x7F) << shift);
    if (bv & 0x80) == 0 {
      return (result_val, pos - start + 1);
    };
    shift = shift + 7;
    pos = pos + 1;
  }
  return (-1, -1);
}

/// Read the varint uncompressed length that opens a raw snappy stream.
/// Returns Err on a malformed header.
pub fn snappy_uncompressed_len(data: &Vec[UInt8]) -> Result[Int, Str] {
  var vv = _get_varint(data, 0);
  if vv.1 < 0 {
    return Err("snappy: malformed varint length");
  };
  return Ok(vv.0);
}

/// Sanity-check the varint header of a raw snappy stream. O(1)..O(10).
pub fn snappy_validate(data: &Vec[UInt8]) -> Bool {
  if data.len() == 0 {
    return false;
  };
  var vv = _get_varint(data, 0);
  return vv.1 >= 0;
}

/// Upper bound on the compressed size of `len` input bytes (varint + up to
/// 1/6 expansion for incompressible data). O(1).
pub fn snappy_max_compressed_len(len: Int) -> Int {
  var l = len;
  if l < 0 {
    l = 0;
  };
  return 32 + l + l / 6;
}

/// Compress `data` into a raw snappy stream (varint length + elements).
/// Greedy matches with a 4KiB window; literals batch until a match is found.
/// Complexity: O(n * 4096).
pub fn snappy_compress(data: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var len = data.len();
  _put_varint(&result, len);
  var pos = 0;
  var lit_start = 0;
  while pos < len {
    var best_len = 0;
    var best_off = 0;
    if pos > 0 {
      var search_start = pos - 4096;
      if search_start < 0 {
        search_start = 0;
      };
      var si = search_start;
      while si < pos {
        var match_len = 0;
        while (si + match_len) < pos && (pos + match_len) < len && match_len < 273 {
          var a = data[si + match_len];
          var b = data[pos + match_len];
          if a != b {
            break;
          };
          match_len = match_len + 1;
        }
        if match_len > best_len && match_len >= 4 {
          best_len = match_len;
          best_off = pos - si;
        };
        si = si + 1;
      }
    };
    // Clamp to what copy2 can encode (length byte holds len-1, max 255).
    // BUG FIX (2026-08-25): without this clamp, matches of 257..273 bytes
    // were emitted as 256-byte copies while pos advanced by the FULL
    // match length -- silently dropping input bytes and desynchronizing
    // every later offset (round-trip failed from ~1000-byte inputs).
    if best_len > 256 {
      best_len = 256;
    };
    if best_len >= 4 && best_off <= 65535 {
      var lit_len = pos - lit_start;
      _snappy_write_literal(&result, data, lit_start, lit_len);
      _snappy_write_copy2(&result, best_len, best_off);
      pos = pos + best_len;
      lit_start = pos;
    } else {
      pos = pos + 1;
    };
  }
  var final_lit = pos - lit_start;
  _snappy_write_literal(&result, data, lit_start, final_lit);
  return result;
}

/// Append a literal element: tag byte with the type bits clear, then the bytes.
fn _snappy_write_literal(out: &mut Vec[UInt8], data: &Vec[UInt8], lit_start: Int, lit_len: Int) {
  if lit_len == 0 {
    return;
  };
  var n = lit_len - 1;
  if n < 60 {
    var tag = (n << 2) as Int;
    out.push(tag as UInt8);
  } else {
    out.push(240 as UInt8);
    if n < 256 {
      out.push(n as UInt8);
    } elif n < 65536 {
      out.push((n & 0xFF) as UInt8);
      out.push(((n >> 8) & 0xFF) as UInt8);
    } else {
      out.push((n & 0xFF) as UInt8);
      out.push(((n >> 8) & 0xFF) as UInt8);
      out.push(((n >> 16) & 0xFF) as UInt8);
    };
  };
  var k = 0;
  while k < lit_len {
    out.push(data[lit_start + k]);
    k = k + 1;
  }
}

/// Append a copy2 element: type bits 10, 16-bit LE offset, length - 1.
fn _snappy_write_copy2(out: &mut Vec[UInt8], mlen: Int, moff: Int) {
  var tag = 2 as Int;
  out.push(tag as UInt8);
  out.push((moff & 0xFF) as UInt8);
  out.push(((moff >> 8) & 0xFF) as UInt8);
  var l = mlen - 1;
  if l > 255 {
    l = 255;
  };
  out.push(l as UInt8);
}

/// Decompress a raw snappy stream. Returns Err on malformed varints, invalid
/// element types, truncated data, or out-of-range copy offsets.
// Default output ceiling for uncapped decompression (1 GiB): bounds
// decompression-bomb amplification. Capped variant accepts an explicit
// limit and also rejects a lying varint declared length up-front.
const _SNAPPY_DEFAULT_CAP: Int = 1073741824;

/// Decompress Snappy data; Err on malformed input.
pub fn snappy_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] {
  return snappy_decompress_capped(data, _SNAPPY_DEFAULT_CAP);
}

/// Decompress with a hard ceiling on output size (bomb guard). The
/// varint-declared length is rejected up-front when it exceeds the cap;
/// every literal/copy element re-checks before writing.
pub fn snappy_decompress_capped(data: &Vec[UInt8], max_out: Int) -> Result[Vec[UInt8], Str] {
  var vv = _get_varint(data, 0);
  if vv.1 < 0 {
    return Err("snappy: malformed varint length");
  };
  if vv.0 > max_out {
    return Err("snappy: declared output exceeds cap");
  };
  var pos = vv.1;
  var len = data.len();
  var result = Vec[UInt8].new();
  while pos < len {
    var tag_b = data[pos];
    var tag = tag_b as Int;
    pos = pos + 1;
    var elem_type = tag & 0x03;
    if elem_type == 0 {
      var lit_len = (tag >> 2) + 1;
      if (tag >> 2) >= 60 {
        var nbytes = (tag >> 2) - 59;
        if nbytes < 1 || nbytes > 4 {
          return Err("snappy: invalid literal length tag");
        };
        if pos + nbytes > len {
          return Err("snappy: truncated literal length");
        };
        var v = 0;
        var k = 0;
        while k < nbytes {
          v = v | ((data[pos + k] as Int) << (8 * k));
          k = k + 1;
        }
        pos = pos + nbytes;
        lit_len = v + 1;
      };
      if pos + lit_len > len {
        return Err("snappy: truncated literal");
      };
      if result.len() + lit_len > max_out {
        return Err("snappy: output exceeds cap");
      };
      var t = 0;
      while t < lit_len {
        result.push(data[pos + t]);
        t = t + 1;
      }
      pos = pos + lit_len;
    } elif elem_type == 1 {
      if pos + 1 > len {
        return Err("snappy: truncated copy1");
      };
      var c1 = data[pos] as Int;
      pos = pos + 1;
      var off = ((tag >> 5) << 8) | c1;
      var clen = ((tag >> 2) & 0x07) + 4;
      var dst_len = result.len();
      if off == 0 || off > dst_len {
        return Err("snappy: invalid copy offset");
      };
      if dst_len + clen > max_out {
        return Err("snappy: output exceeds cap");
      };
      var k2 = 0;
      while k2 < clen {
        var src_idx = dst_len - off + (k2 % off);
        result.push(result[src_idx]);
        k2 = k2 + 1;
      }
    } elif elem_type == 2 {
      if pos + 3 > len {
        return Err("snappy: truncated copy2");
      };
      var o0 = data[pos] as Int;
      var o1 = data[pos + 1] as Int;
      var c2 = data[pos + 2] as Int;
      pos = pos + 3;
      var off2 = o0 | (o1 << 8);
      var clen2 = c2 + 1;
      var dst_len2 = result.len();
      if off2 == 0 || off2 > dst_len2 {
        return Err("snappy: invalid copy offset");
      };
      if dst_len2 + clen2 > max_out {
        return Err("snappy: output exceeds cap");
      };
      var k3 = 0;
      while k3 < clen2 {
        var src_idx2 = dst_len2 - off2 + (k3 % off2);
        result.push(result[src_idx2]);
        k3 = k3 + 1;
      }
    } else {
      return Err("snappy: reserved element type");
    };
  }
  return Ok(result);
}

/// Compress `data` into a framed stream: varint(compressed payload length)
/// followed by the raw snappy stream (which itself starts with the varint
/// uncompressed length). The frame is self-delimiting.
pub fn snappy_compress_frame(data: &Vec[UInt8]) -> Vec[UInt8] {
  var inner = snappy_compress(data);
  var result = Vec[UInt8].new();
  _put_varint(&result, inner.len());
  var i = 0;
  var ilen = inner.len();
  while i < ilen {
    result.push(inner[i]);
    i = i + 1;
  }
  return result;
}

/// Decompress a snappy_compress_frame stream. Validates the outer varint
/// against the remaining bytes. Returns Err on any mismatch or malformed data.
pub fn snappy_decompress_frame(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] {
  var vv = _get_varint(data, 0);
  if vv.1 < 0 {
    return Err("snappy: malformed frame varint");
  };
  var pos = vv.1;
  var len = data.len();
  if pos + vv.0 > len {
    return Err("snappy: frame length exceeds data");
  };
  if pos + vv.0 != len {
    return Err("snappy: trailing bytes after frame");
  };
  var inner = Vec[UInt8].new();
  while pos < len {
    inner.push(data[pos]);
    pos = pos + 1;
  }
  return snappy_decompress(&inner);
}
