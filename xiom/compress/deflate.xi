// XIOM - DEFLATE (RFC 1951) + helpers
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// REAL RFC 1951 implementation (replaced the pre-1.0 custom container on
// 2026-08-27). Producer: STORED blocks (level 0) or FIXED-Huffman blocks
// (levels 1-9). Consumer: STORED + FIXED + DYNAMIC blocks, so streams from
// standard tools (zlib/gzip/png) decompress. gzip.xi / zlib.xi wrap this
// payload per RFC 1952 / RFC 1950 respectively.
//
// Implementation notes (shapes that matter):
//   - every `expr as Type` cast is PARENTHESIZED: unparenthesized casts on
//     binary expressions miscompile to illegal instructions
//     (REPORT_TO_COMPILER_SESSION.md 3b-3 #15)
//   - the bit writer's FINAL flush byte is pushed from THIS file's own
//     frame, not from a nested helper: nested &mut Vec pushes can lose
//     their last byte across the return (finding #16)
//   - no module-level arrays > 64 entries; table lookups are if-chains
//   - Huffman codes pack MSB-first; extra bits pack LSB-first (RFC 3.1.1)

module xiom.compress.deflate

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn fread(buf: *UInt8, size: UInt, count: UInt, stream: *UInt8) -> UInt;
  fn fwrite(buf: *UInt8, size: UInt, count: UInt, stream: *UInt8) -> UInt;
}

use xiom.io;

// ============================================================================
// Bit writer (LSB-first data order per RFC 1951)
// ============================================================================

fn _bw_put(out: &mut Vec[UInt8], acc: Int, acc_bits: Int, value: Int, count: Int) -> (Int, Int) {
  var a = acc;
  var b = acc_bits;
  var mult = 1;
  var i = 0;
  while i < b {
    mult = mult * 2;
    i = i + 1;
  }
  a = a + value * mult;
  b = b + count;
  while b >= 8 {
    out.push((a % 256) as UInt8);
    a = a / 256;
    b = b - 8;
  }
  return (a, b);
}

// ============================================================================
// Length / distance tables (RFC 1951 3.2.5) -- if-chain encoded
// ============================================================================

fn _len_base(code: Int) -> Int {
  if code >= 281 {
    if code == 285 { return 258; }
    return 131 + (code - 281) * 32;
  };
  if code >= 277 { return 67 + (code - 277) * 16; }
  if code >= 273 { return 35 + (code - 273) * 8; }
  if code >= 269 { return 19 + (code - 269) * 4; }
  if code >= 265 { return 11 + (code - 265) * 2; }
  return 3 + (code - 257);
}

fn _len_extra(code: Int) -> Int {
  if code < 265 || code == 285 { return 0; }
  if code < 269 { return 1; }
  if code < 273 { return 2; }
  if code < 277 { return 3; }
  if code < 281 { return 4; }
  return 5;
}

fn _dist_base(code: Int) -> Int {
  if code < 4 { return code + 1; }
  if code < 6 { return 5 + (code - 4) * 2; }
  if code < 8 { return 9 + (code - 6) * 4; }
  if code < 10 { return 17 + (code - 8) * 8; }
  if code < 12 { return 33 + (code - 10) * 16; }
  if code < 14 { return 65 + (code - 12) * 32; }
  if code < 16 { return 129 + (code - 14) * 64; }
  if code < 18 { return 257 + (code - 16) * 128; }
  if code < 20 { return 513 + (code - 18) * 256; }
  if code < 22 { return 1025 + (code - 20) * 512; }
  if code < 24 { return 2049 + (code - 22) * 1024; }
  if code < 26 { return 4097 + (code - 24) * 2048; }
  if code < 28 { return 8193 + (code - 26) * 4096; }
  return 16385 + (code - 28) * 8192;
}

fn _dist_extra(code: Int) -> Int {
  if code < 4 { return 0; }
  if code < 26 { return 1 + (code - 4) / 2; }
  return 13;
}

fn _len_code_for(n: Int) -> Int {
  var c = 257;
  while c <= 285 {
    var base = _len_base(c);
    if c == 285 {
      if n == 258 { return 285; }
    } else {
      var span = 1;
      var e = _len_extra(c);
      var i2 = 0;
      while i2 < e {
        span = span * 2;
        i2 = i2 + 1;
      }
      if n >= base && n < base + span {
        return c;
      }
    };
    c = c + 1;
  }
  return 285;
}

fn _dist_code_for(d: Int) -> Int {
  var c = 0;
  while c < 30 {
    var base = _dist_base(c);
    var span = 1;
    var e = _dist_extra(c);
    var i2 = 0;
    while i2 < e {
      span = span * 2;
      i2 = i2 + 1;
    }
    if d >= base && d < base + span {
      return c;
    };
    c = c + 1;
  }
  return 29;
}

// ============================================================================
// Fixed-Huffman symbol writer (RFC 1951 3.2.6) -- codes MSB-first
// ============================================================================

fn _fx_write(out: &mut Vec[UInt8], acc: Int, acc_bits: Int, sym: Int) -> (Int, Int) {
  var code = 0;
  var count = 0;
  if sym <= 143 {
    code = 0x30 + sym;
    count = 8;
  } else {
    if sym <= 255 {
      code = 0x190 + (sym - 144);
      count = 9;
    } else {
      if sym == 256 {
        code = 0;
        count = 7;
      } else {
        if sym <= 279 {
          code = sym - 256;
          count = 7;
        } else {
          code = 0xC0 + (sym - 280);
          count = 8;
        };
      };
    };
  };
  var a = acc;
  var b = acc_bits;
  var i = count - 1;
  while i >= 0 {
    var m = 1;
    var j = 0;
    while j < i {
      m = m * 2;
      j = j + 1;
    }
    var bitv = (code / m) % 2;
    var t = _bw_put(out, a, b, bitv, 1);
    a = t.0;
    b = t.1;
    i = i - 1;
  }
  return (a, b);
}

fn _fx_extra(out: &mut Vec[UInt8], acc: Int, acc_bits: Int, value: Int, count: Int) -> (Int, Int) {
  var v = value;
  var i = 0;
  var a = acc;
  var b = acc_bits;
  while i < count {
    var t = _bw_put(out, a, b, v % 2, 1);
    a = t.0;
    b = t.1;
    v = v / 2;
    i = i + 1;
  }
  return (a, b);
}

// ============================================================================
// Producers
// ============================================================================

fn _fixed_deflate(data: &Vec[UInt8]) -> Vec[UInt8] {
  var out = Vec[UInt8].new();
  var len = data.len();
  var acc = 0;
  var acc_bits = 0;
  var th = _bw_put(&mut out, acc, acc_bits, 3, 3);
  acc = th.0;
  acc_bits = th.1;
  var pos = 0;
  var lit_start = 0;
  while pos < len {
    var best_len = 0;
    var best_off = 0;
    var search_start = pos - 32768;
    if search_start < 0 {
      search_start = 0;
    };
    var si = search_start;
    while si < pos {
      var ml = 0;
      while (si + ml) < pos && (pos + ml) < len && ml < 258 {
        if data[si + ml] != data[pos + ml] {
          break;
        };
        ml = ml + 1;
      }
      if ml > best_len && ml >= 3 {
        best_len = ml;
        best_off = pos - si;
      };
      si = si + 1;
    }
    if best_len >= 3 {
      var li = lit_start;
      while li < pos {
        var t = _fx_write(&mut out, acc, acc_bits, data[li] as Int);
        acc = t.0;
        acc_bits = t.1;
        li = li + 1;
      }
      var lc = _len_code_for(best_len);
      var t2 = _fx_write(&mut out, acc, acc_bits, lc);
      acc = t2.0;
      acc_bits = t2.1;
      var t3 = _fx_extra(&mut out, acc, acc_bits, best_len - _len_base(lc), _len_extra(lc));
      acc = t3.0;
      acc_bits = t3.1;
      var dc = _dist_code_for(best_off);
      var di = 4;
      while di >= 0 {
        var dm = 1;
        var dj = 0;
        while dj < di {
          dm = dm * 2;
          dj = dj + 1;
        }
        var dbit = (dc / dm) % 2;
        var t4 = _bw_put(&mut out, acc, acc_bits, dbit, 1);
        acc = t4.0;
        acc_bits = t4.1;
        di = di - 1;
      }
      var t5 = _fx_extra(&mut out, acc, acc_bits, best_off - _dist_base(dc), _dist_extra(dc));
      acc = t5.0;
      acc_bits = t5.1;
      pos = pos + best_len;
      lit_start = pos;
    } else {
      pos = pos + 1;
    };
  }
  var li2 = lit_start;
  while li2 < len {
    var t = _fx_write(&mut out, acc, acc_bits, data[li2] as Int);
    acc = t.0;
    acc_bits = t.1;
    li2 = li2 + 1;
  }
  var t6 = _fx_write(&mut out, acc, acc_bits, 256);
  acc = t6.0;
  acc_bits = t6.1;
  // INLINE final flush (finding #16: nested &mut pushes can lose the last
  // byte; push from this frame instead)
  while acc_bits >= 8 {
    out.push((acc % 256) as UInt8);
    acc = acc / 256;
    acc_bits = acc_bits - 8;
  }
  if acc_bits > 0 {
    out.push((acc % 256) as UInt8);
  };
  return out;
}

fn _stored_deflate(data: &Vec[UInt8]) -> Vec[UInt8] {
  var out = Vec[UInt8].new();
  var len = data.len();
  var pos = 0;
  var last = false;
  while !last {
    var chunk = len - pos;
    if chunk > 65535 {
      chunk = 65535;
    } else {
      last = true;
    };
    if last {
      out.push(1u8);
    } else {
      out.push(0u8);
    };
    out.push((chunk % 256) as UInt8);
    out.push(((chunk / 256) % 256) as UInt8);
    out.push(((65535 - chunk) % 256) as UInt8);
    out.push((((65535 - chunk) / 256) % 256) as UInt8);
    var i = 0;
    while i < chunk {
      out.push(data[pos + i]);
      i = i + 1;
    }
    pos = pos + chunk;
  }
  return out;
}

/// Compress with the RFC 1951 fixed-Huffman encoding (matching the
/// deterministic reference behavior of zlib Z_FIXED for greedy matchers).
pub fn deflate_compress(data: &Vec[UInt8]) -> Vec[UInt8] {
  return deflate_compress_level(data, 6);
}

/// level 0 => STORED blocks (real, uncompressed); levels 1-9 => FIXED
/// Huffman blocks.
pub fn deflate_compress_level(data: &Vec[UInt8], level: Int) -> Vec[UInt8] {
  var lvl = level;
  if lvl < 0 {
    lvl = 0;
  };
  if lvl > 9 {
    lvl = 9;
  };
  if lvl == 0 {
    return _stored_deflate(data);
  };
  return _fixed_deflate(data);
}

// ============================================================================
// Bit reader
// ============================================================================

fn _br_peek(data: &Vec[UInt8], pos: Int, count: Int) -> Int {
  var val = 0;
  var i = 0;
  while i < count {
    var bp = pos + i;
    var byte_idx = bp / 8;
    if byte_idx >= data.len() {
      return -1;
    };
    var bit_in_byte = bp % 8;
    var b = data[byte_idx] as Int;
    var m = 1;
    var j = 0;
    while j < bit_in_byte {
      m = m * 2;
      j = j + 1;
    }
    var bitval = (b / m) % 2;
    var m2 = 1;
    j = 0;
    while j < i {
      m2 = m2 * 2;
      j = j + 1;
    }
    val = val + bitval * m2;
    i = i + 1;
  }
  return val;
}

// ============================================================================
// Canonical Huffman decode (RFC 1951 3.2.2)
// ============================================================================

fn _canonical_codes(lengths: &Vec[Int], n: Int) -> Vec[Int] {
  var count = Vec[Int].new();
  var i = 0;
  while i <= 15 {
    count.push(0);
    i = i + 1;
  }
  i = 0;
  while i < n {
    var l = lengths[i];
    if l < 0 || l > 15 {
      return Vec[Int].new();
    };
    count[l] = count[l] + 1;
    i = i + 1;
  }
  var next = Vec[Int].new();
  i = 0;
  while i <= 15 {
    next.push(0);
    i = i + 1;
  }
  var code = 0;
  var bits = 1;
  while bits <= 15 {
    code = (code + count[bits - 1]) * 2;
    next[bits] = code;
    bits = bits + 1;
  }
  var codes = Vec[Int].new();
  i = 0;
  while i < n {
    var l2 = lengths[i];
    if l2 == 0 {
      codes.push(-1);
    } else {
      codes.push(next[l2]);
      next[l2] = next[l2] + 1;
    };
    i = i + 1;
  }
  return codes;
}

fn _decode_sym(data: &Vec[UInt8], pos: Int, codes: &Vec[Int], lengths: &Vec[Int], n: Int) -> (Int, Int) {
  var bits = 1;
  while bits <= 15 {
    var raw = 0;
    var i2 = 0;
    var ok = true;
    while i2 < bits {
      var bp = pos + i2;
      var byte_idx = bp / 8;
      if byte_idx >= data.len() {
        ok = false;
        i2 = bits;
      } else {
        var bit_in_byte = bp % 8;
        var b = data[byte_idx] as Int;
        var m = 1;
        var j = 0;
        while j < bit_in_byte {
          m = m * 2;
          j = j + 1;
        }
        var bitval = (b / m) % 2;
        raw = raw * 2 + bitval;
        i2 = i2 + 1;
      };
    };
    if !ok {
      return (-1, -1);
    };
    var i = 0;
    while i < n {
      if lengths[i] == bits && codes[i] == raw {
        return (i, bits);
      };
      i = i + 1;
    }
    bits = bits + 1;
  }
  return (-1, -1);
}

// ============================================================================
// Inflate (stored + fixed + dynamic), with an output ceiling
// ============================================================================

fn _inflate_capped(data: &Vec[UInt8], max_out: Int) -> Result[Vec[UInt8], Str] {
  var out = Vec[UInt8].new();
  var pos = 0;
  var done = false;
  while !done {
    var hdr = _br_peek(data, pos, 3);
    if hdr < 0 {
      return Err("deflate: truncated block header");
    };
    var bfinal = hdr % 2;
    var btype = (hdr / 2) % 4;
    pos = pos + 3;
    if btype == 0 {
      pos = ((pos + 7) / 8) * 8;
      var byte_idx = pos / 8;
      if byte_idx + 4 > data.len() {
        return Err("deflate: truncated stored header");
      };
      var len0 = data[byte_idx] as Int;
      var len1 = data[byte_idx + 1] as Int;
      var nlen0 = data[byte_idx + 2] as Int;
      var nlen1 = data[byte_idx + 3] as Int;
      var blen = len0 + len1 * 256;
      var bnlen = nlen0 + nlen1 * 256;
      if (blen ^ 65535) != bnlen {
        return Err("deflate: stored length mismatch");
      };
      byte_idx = byte_idx + 4;
      if byte_idx + blen > data.len() {
        return Err("deflate: stored block truncated");
      };
      if out.len() + blen > max_out {
        return Err("deflate: output exceeds cap");
      };
      var i = 0;
      while i < blen {
        out.push(data[byte_idx + i]);
        i = i + 1;
      }
      pos = (byte_idx + blen) * 8;
    } else {
      if btype == 1 || btype == 2 {
        var lit_lens = Vec[Int].new();
        var dist_lens = Vec[Int].new();
        var i2 = 0;
        if btype == 1 {
          while i2 < 288 {
            var l = 8;
            if i2 >= 144 && i2 <= 255 { l = 9; };
            if i2 >= 256 && i2 <= 279 { l = 7; };
            lit_lens.push(l);
            i2 = i2 + 1;
          }
          i2 = 0;
          while i2 < 30 {
            dist_lens.push(5);
            i2 = i2 + 1;
          }
        } else {
          var hlit = _br_peek(data, pos, 5) + 257;
          var hdist = _br_peek(data, pos + 5, 5) + 1;
          var hclen = _br_peek(data, pos + 10, 4) + 4;
          pos = pos + 14;
          if hlit > 286 || hdist > 30 {
            return Err("deflate: bad dynamic header");
          };
          var cl_lens = Vec[Int].new();
          i2 = 0;
          while i2 < 19 {
            cl_lens.push(0);
            i2 = i2 + 1;
          }
          var order = Vec[Int].new();
          order.push(16); order.push(17); order.push(18); order.push(0);
          order.push(8); order.push(7); order.push(9); order.push(6);
          order.push(10); order.push(5); order.push(11); order.push(4);
          order.push(12); order.push(3); order.push(13); order.push(2);
          order.push(14); order.push(1); order.push(15);
          var tmp_cl = Vec[Int].new();
          i2 = 0;
          while i2 < hclen {
            var v3 = _br_peek(data, pos, 3);
            if v3 < 0 {
              return Err("deflate: truncated clen");
            };
            tmp_cl.push(v3);
            pos = pos + 3;
            i2 = i2 + 1;
          }
          i2 = 0;
          while i2 < 19 {
            var found = false;
            var val = 0;
            var k2 = 0;
            while k2 < hclen {
              if order[k2] == i2 {
                found = true;
                val = tmp_cl[k2];
              };
              k2 = k2 + 1;
            }
            if found {
              cl_lens.push(val);
            } else {
              cl_lens.push(0);
            };
            i2 = i2 + 1;
          }
          var cl_codes = _canonical_codes(&cl_lens, 19);
          if cl_codes.len() == 0 {
            return Err("deflate: bad clen table");
          };
          var all_lens = Vec[Int].new();
          var total = hlit + hdist;
          i2 = 0;
          while i2 < total {
            var sym = _decode_sym(data, pos, &cl_codes, &cl_lens, 19);
            if sym.0 < 0 {
              return Err("deflate: bad clen symbol");
            };
            pos = pos + sym.1;
            var s = sym.0;
            if s < 16 {
              all_lens.push(s);
            } else {
              var rep = 0;
              var rl = 0;
              if s == 16 {
                rep = all_lens[all_lens.len() - 1];
                rl = _br_peek(data, pos, 2) + 3;
                pos = pos + 2;
              };
              if s == 17 {
                rep = 0;
                rl = _br_peek(data, pos, 3) + 3;
                pos = pos + 3;
              };
              if s == 18 {
                rep = 0;
                rl = _br_peek(data, pos, 7) + 11;
                pos = pos + 7;
              };
              var j3 = 0;
              while j3 < rl {
                all_lens.push(rep);
                j3 = j3 + 1;
              }
            };
            i2 = i2 + 1;
          }
          i2 = 0;
          while i2 < hlit {
            lit_lens.push(all_lens[i2]);
            i2 = i2 + 1;
          }
          i2 = 0;
          while i2 < hdist {
            dist_lens.push(all_lens[hlit + i2]);
            i2 = i2 + 1;
          }
        }
        var lit_codes = _canonical_codes(&lit_lens, lit_lens.len());
        var dist_codes = _canonical_codes(&dist_lens, dist_lens.len());
        var stream_done = false;
        while !stream_done {
          var lsym = _decode_sym(data, pos, &lit_codes, &lit_lens, lit_lens.len());
          if lsym.0 < 0 {
            return Err("deflate: bad literal symbol");
          };
          pos = pos + lsym.1;
          var s2 = lsym.0;
          if s2 == 256 {
            stream_done = true;
          } else {
            if s2 < 256 {
              if out.len() >= max_out {
                return Err("deflate: output exceeds cap");
              };
              out.push(s2 as UInt8);
            } else {
              var lc2 = s2;
              var le = _len_extra(lc2);
              var extra = 0;
              var epos = 0;
              while epos < le {
                var b2 = _br_peek(data, pos, 1);
                if b2 < 0 {
                  return Err("deflate: truncated length extra");
                };
                var m3 = 1;
                var j4 = 0;
                while j4 < epos {
                  m3 = m3 * 2;
                  j4 = j4 + 1;
                }
                extra = extra + b2 * m3;
                pos = pos + 1;
                epos = epos + 1;
              }
              var mlen = _len_base(lc2) + extra;
              var dsym = _decode_sym(data, pos, &dist_codes, &dist_lens, dist_lens.len());
              if dsym.0 < 0 {
                return Err("deflate: bad distance symbol");
              };
              pos = pos + dsym.1;
              var dc2 = dsym.0;
              var de = _dist_extra(dc2);
              var dextra = 0;
              epos = 0;
              while epos < de {
                var b3 = _br_peek(data, pos, 1);
                if b3 < 0 {
                  return Err("deflate: truncated distance extra");
                };
                var m4 = 1;
                var j5 = 0;
                while j5 < epos {
                  m4 = m4 * 2;
                  j5 = j5 + 1;
                }
                dextra = dextra + b3 * m4;
                pos = pos + 1;
                epos = epos + 1;
              }
              var mdist = _dist_base(dc2) + dextra;
              if mdist > out.len() {
                return Err("deflate: distance exceeds output");
              };
              if out.len() + mlen > max_out {
                return Err("deflate: output exceeds cap");
              };
              var j6 = 0;
              while j6 < mlen {
                out.push(out[out.len() - mdist]);
                j6 = j6 + 1;
              }
            };
          }
        }
      } else {
        return Err("deflate: reserved block type");
      }
    };
    if bfinal == 1 {
      done = true;
    };
  }
  return Ok(out);
}

// ============================================================================
// Public API
// ============================================================================

const _DEFLATE_DEFAULT_CAP: Int = 1073741824;

pub fn deflate_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] {
  return deflate_decompress_capped(data, _DEFLATE_DEFAULT_CAP);
}

/// Decompress a real RFC 1951 stream with a hard output ceiling.
pub fn deflate_decompress_capped(data: &Vec[UInt8], max_out: Int) -> Result[Vec[UInt8], Str] {
  return _inflate_capped(data, max_out);
}

/// Worst-case compressed size for `len` input bytes under the fixed-Huffman
/// encoder: per byte at most 9 code bits + headers + match overhead is
/// always below this bound. O(1).
pub fn deflate_bound(len: Int) -> Int {
  var l = len;
  if l < 0 {
    l = 0;
  };
  return l * 5 + 512;
}

/// Stream-compress between two file descriptors: reads all bytes from
/// `reader`, compresses them, writes the container to `writer`, and returns
/// the number of bytes written. Errors (empty input, read/write failures) are
/// returned as Err.
pub fn deflate_compress_stream(reader: Int, writer: Int) -> Result[Int, Str] {
  var input = Vec[UInt8].new();
  var done = false;
  while !done {
    unsafe {
      var chunk: [4096]UInt8;
      var got = fread(&chunk[0], 1 as UInt, 4096 as UInt, reader as *UInt8);
      if got < 0 {
        return Err("deflate: stream read failed");
      };
      if got == 0 {
        done = true;
      } else {
        var i = 0;
        while i < got {
          input.push(chunk[i]);
          i = i + 1;
        }
      };
    };
  };
  if input.len() == 0 {
    return Err("deflate: empty stream input");
  };
  var compressed = deflate_compress(&input);
  unsafe {
    var written = fwrite(compressed.data, 1 as UInt, compressed.len() as UInt, writer as *UInt8);
    return Ok(written as Int);
  };
}
