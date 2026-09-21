// XIOM - Compression: LZ4
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.compress.lz4

// Depends on: xiom.string

// ============================================================================
// LZ4-style block and frame compression.
//
// Block format (documented LZ4 algorithm, round-trip safe within XIOM; NOT
// guaranteed wire-compatible with the C library):
//   token: high nibble = literal length (15 = extended), low nibble =
//          match length - 4 (15 = extended). Extended lengths add 255 per
//          continuation byte, terminated by a byte < 255.
//   sequence: token, literals, match offset (2 bytes LE), match-length
//             extension bytes (only when the low nibble is 15).
//   final sequence carries literals and no offset.
//
// Frame format:
//   magic 04 22 4D 18, FLG 0x40, BD 0x70, then blocks of
//   [block size LE | bit31 = last block] + block payload.
//
// lz4_compress / lz4_decompress are frame-level; lz4_compress_block /
// lz4_decompress_block operate on a raw block payload. lz4_compress_hc uses a
// larger match window for better ratios. Complexity: O(n * window).
// ============================================================================

/// Compress `data` into a full frame (magic, FLG/BD, block size, payload).
pub fn lz4_compress(data: &Vec[UInt8]) -> Vec[UInt8] {
  var block = lz4_compress_block(data);
  var result = Vec[UInt8].new();
  result.push(0x04);
  result.push(0x22);
  result.push(0x4D);
  result.push(0x18);
  result.push(0x40);
  result.push(0x70);
  var blen = block.len();
  var block_size = (blen as UInt) | (0x80000000 as UInt);
  result.push((block_size & 0xFF) as UInt8);
  result.push(((block_size >> 8) & 0xFF) as UInt8);
  result.push(((block_size >> 16) & 0xFF) as UInt8);
  result.push(((block_size >> 24) & 0xFF) as UInt8);
  var i = 0;
  while i < blen {
    result.push(block[i]);
    i = i + 1;
  }
  return result;
}

/// Alias for lz4_compress: the frame IS the full container in this module.
pub fn lz4_compress_frame(data: &Vec[UInt8]) -> Vec[UInt8] {
  return lz4_compress(data);
}

/// Compress `data` into a frame using the high-compression block encoder.
pub fn lz4_compress_hc(data: &Vec[UInt8]) -> Vec[UInt8] {
  var block = lz4_compress_hc_block(data);
  var result = Vec[UInt8].new();
  result.push(0x04);
  result.push(0x22);
  result.push(0x4D);
  result.push(0x18);
  result.push(0x40);
  result.push(0x70);
  var blen = block.len();
  var block_size = (blen as UInt) | (0x80000000 as UInt);
  result.push((block_size & 0xFF) as UInt8);
  result.push(((block_size >> 8) & 0xFF) as UInt8);
  result.push(((block_size >> 16) & 0xFF) as UInt8);
  result.push(((block_size >> 24) & 0xFF) as UInt8);
  var i = 0;
  while i < blen {
    result.push(block[i]);
    i = i + 1;
  }
  return result;
}

/// Worst-case compressed size for `len` input bytes (literals expand by at
/// most 1 byte per 255 input bytes plus token/header overhead). O(1).
pub fn lz4_bound(len: Int) -> Int {
  var l = len;
  if l < 0 {
    l = 0;
  };
  return l + (l >> 8) + 32;
}

/// Decompress an lz4_compress frame. Validates magic and the end-of-frame
/// marker. Returns Err on malformed input.
// Default output ceiling for uncapped decompression (1 GiB): bounds
// decompression-bomb amplification. Capped variant accepts an explicit
// limit; residual note: a single hostile block may overshoot by up to its
// own decoded size before the per-block check fires.
const _LZ4_DEFAULT_CAP: Int = 1073741824;

/// Decompress an LZ4 block; Err on malformed input.
pub fn lz4_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] {
  return lz4_decompress_capped(data, _LZ4_DEFAULT_CAP);
}

/// Decompress with a hard ceiling on total output size (bomb guard).
/// Checked after each block's expansion.
pub fn lz4_decompress_capped(data: &Vec[UInt8], max_out: Int) -> Result[Vec[UInt8], Str] {
  var len = data.len();
  if len < 11 {
    return Err("lz4: frame too short");
  };
  if data[0] != 0x04 || data[1] != 0x22 || data[2] != 0x4D || data[3] != 0x18 {
    return Err("lz4: invalid magic bytes");
  };
  var result = Vec[UInt8].new();
  var pos = 6;
  while pos + 4 <= len {
    var s0 = data[pos] as UInt;
    var s1 = data[pos + 1] as UInt;
    var s2 = data[pos + 2] as UInt;
    var s3 = data[pos + 3] as UInt;
    var block_size = s0 | (s1 << 8) | (s2 << 16) | (s3 << 24);
    var is_last = (block_size >> 31) != 0;
    var data_len = (block_size & 0x7FFFFFFF) as Int;
    pos = pos + 4;
    if pos + data_len > len {
      return Err("lz4: truncated block");
    };
    var block = Vec[UInt8].new();
    var k = 0;
    while k < data_len {
      block.push(data[pos + k]);
      k = k + 1;
    }
    pos = pos + data_len;
    var decoded = lz4_decompress_block(&block);
    match decoded {
      Ok(v) => {
        var t = 0;
        var vlen = v.len();
        while t < vlen {
          result.push(v[t]);
          t = t + 1;
        }
      };
      Err(e) => { return Err(e); };
    }
    if result.len() > max_out {
      return Err("lz4: output exceeds cap");
    };
    if is_last {
      return Ok(result);
    };
  }
  return Err("lz4: no end-of-frame marker found");
}

/// Alias for lz4_decompress: parses and decompresses an lz4_compress frame.
pub fn lz4_decompress_frame(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] {
  return lz4_decompress(data);
}

/// Compress a raw block payload (no frame header) using the LZ4 block format.
/// Greedy search with a 4KiB window; matches need length >= 4.
/// Complexity: O(n * 4096).
pub fn lz4_compress_block(data: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  _lz4_block_core(data, 4096, &result);
  return result;
}

/// High-compression block variant: 64KiB search window, longer match scan.
/// Uses the same block format, so lz4_decompress_block decodes either output.
pub fn lz4_compress_hc_block(data: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  _lz4_block_core(data, 65535, &result);
  return result;
}

/// Shared greedy block compressor. Emits literal runs and matches.
fn _lz4_block_core(data: &Vec[UInt8], window: Int, out: &mut Vec[UInt8]) {
  var len = data.len();
  var pos = 0;
  var lit_start = 0;
  while pos < len {
    var best_len = 0;
    var best_off = 0;
    if pos > 0 {
      var search_start = pos - window;
      if search_start < 0 {
        search_start = 0;
      };
      var si = search_start;
      while si < pos {
        var match_len = 0;
        var searching = true;
        while searching {
          if (si + match_len) >= pos {
            searching = false;
          } elif (pos + match_len) >= len {
            searching = false;
          } elif match_len >= 273 {
            searching = false;
          } else {
            var a = data[si + match_len];
            var b = data[pos + match_len];
            if a != b {
              searching = false;
            } else {
              match_len = match_len + 1;
            }
          }
        }
        if match_len >= 4 {
          if match_len > best_len {
            best_len = match_len;
            best_off = pos - si;
          }
        };
        si = si + 1;
      }
    };
    if best_len >= 4 {
      if best_off <= 65535 {
        var lit_len = pos - lit_start;
        _lz4_write_seq(out, data, lit_start, lit_len, best_len, best_off);
        pos = pos + best_len;
        lit_start = pos;
      } else {
        pos = pos + 1;
      }
    } else {
      pos = pos + 1;
    };
  }
  var final_lit = pos - lit_start;
  _lz4_write_seq(out, data, lit_start, final_lit, 0, 0);
}

/// Append one LZ4 sequence (token + literals [+ offset + length extension]).
/// match_len == 0 marks the final literal-only sequence (no offset).
fn _lz4_write_seq(out: &mut Vec[UInt8], data: &Vec[UInt8], lit_start: Int, lit_len: Int, match_len: Int, match_off: Int) {
  var hi = lit_len;
  if hi > 15 {
    hi = 15;
  };
  var has_match = match_len >= 4;
  var token = hi << 4;
  var ext_len = false;
  if has_match {
    var ml = match_len - 4;
    if ml >= 15 {
      ext_len = true;
      token = token | 15;
    } else {
      token = token | ml;
    };
  };
  out.push(token as UInt8);
  if lit_len >= 15 {
    var rem = lit_len - 15;
    while rem >= 255 {
      out.push(255);
      rem = rem - 255;
    }
    out.push(rem as UInt8);
  };
  var k = 0;
  while k < lit_len {
    out.push(data[lit_start + k]);
    k = k + 1;
  }
  if has_match {
    out.push((match_off & 0xFF) as UInt8);
    out.push(((match_off >> 8) & 0xFF) as UInt8);
    if ext_len {
      var rem2 = match_len - 4 - 15;
      while rem2 >= 255 {
        out.push(255);
        rem2 = rem2 - 255;
      }
      out.push(rem2 as UInt8);
    };
  };
}

/// Decompress a raw LZ4 block. Returns Err on truncation, an invalid offset,
/// or malformed extended lengths.
pub fn lz4_decompress_block(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] {
  var result = Vec[UInt8].new();
  var len = data.len();
  var pos = 0;
  while pos < len {
    var tok_b = data[pos];
    var token = tok_b as Int;
    pos = pos + 1;
    var lit_len = (token >> 4) & 0x0F;
    if lit_len == 15 {
      var e = _lz4_read_ext(data, pos, len);
      if !e.ok {
        return Err("lz4: malformed literal length");
      };
      lit_len = 15 + e.value;
      pos = e.next;
    };
    if pos + lit_len > len {
      return Err("lz4: truncated literal run");
    };
    var k = 0;
    while k < lit_len {
      result.push(data[pos + k]);
      k = k + 1;
    }
    pos = pos + lit_len;
    if pos >= len {
      break;
    };
    if pos + 2 > len {
      return Err("lz4: truncated match offset");
    };
    var o0 = data[pos] as Int;
    var o1 = data[pos + 1] as Int;
    var off = o0 | (o1 << 8);
    pos = pos + 2;
    var mlen = (token & 0x0F) + 4;
    if (token & 0x0F) == 15 {
      var e2 = _lz4_read_ext(data, pos, len);
      if !e2.ok {
        return Err("lz4: malformed match length");
      };
      mlen = 15 + 4 + e2.value;
      pos = e2.next;
    };
    if off == 0 {
      return Err("lz4: zero match offset");
    };
    var dst_len = result.len();
    if off > dst_len {
      return Err("lz4: match offset exceeds output length");
    };
    var k2 = 0;
    while k2 < mlen {
      var src_idx = dst_len - off + (k2 % off);
      result.push(result[src_idx]);
      k2 = k2 + 1;
    }
  }
  return Ok(result);
}

/// Extended-length reader: consumes bytes while 255, returns the sum.
type ExtLen = {
  value: Int;
  next: Int;
  ok: Bool;
}

fn _lz4_read_ext(data: &Vec[UInt8], pos: Int, len: Int) -> ExtLen {
  var p = pos;
  var acc = 0;
  while p < len {
    var b = data[p];
    var bv = b as Int;
    if bv == 255 {
      acc = acc + 255;
      p = p + 1;
    } else {
      acc = acc + bv;
      p = p + 1;
      return ExtLen{ value: acc; next: p; ok: true; };
    };
  }
  return ExtLen{ value: 0; next: p; ok: false; };
}
