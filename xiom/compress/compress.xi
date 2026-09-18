// XIOM -- Compression
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.compress
use xiom.compress.deflate;
use xiom.compress.lz77;
use xiom.compress.huffman;
use xiom.compress.gzip;
use xiom.compress.zlib;
use xiom.compress.brotli;
use xiom.compress.lz4;
use xiom.compress.snappy;

use xiom.string;

// === Compression traits ===
/// === Compression traits ===
pub interface Compressor {
  fn compress(self, data: &Vec[UInt8]) -> Result<Vec[UInt8], Str>;
  fn decompress(self, data: &Vec[UInt8]) -> Result<Vec[UInt8], Str>;
}

// === Gzip ===
/// === Gzip ===
pub type GzipCompressor = { level: Int; }

pub fn GzipCompressor.new() -> GzipCompressor {
  return GzipCompressor{ level: 6 };
}

pub fn GzipCompressor.with_level(level: Int) -> GzipCompressor {
  var lvl = level;
  if lvl < 0 { lvl = 0; };
  if lvl > 9 { lvl = 9; };
  return GzipCompressor{ level: lvl };
}

fn GzipCompressor.compress(self, data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  gzip_compress_level(data, self.level)
}

fn GzipCompressor.decompress(self, data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  gzip_decompress(data)
}

// === CRC32 (bitwise, no lookup table) ===
// NOTE: the module-global [256]UInt table element writes go to a stack copy
// (BUG 2 family -- array elements on module globals) so the table never
// initialized and gzip CRCs were NOT real-gzip compatible. The bitwise form
// is table-free, correct, and interoperable with external gzip tools.
fn crc32(data: &Vec[UInt8]) -> UInt {
  var crc = 0xFFFFFFFF as UInt;
  var i = 0;
  let len = data.len();
  while i < len {
    crc = crc ^ (data[i] as UInt);
    var j = 0;
    while j < 8 {
      if (crc & 1) == 1 {
        crc = (crc >> 1) ^ 0xEDB88320 as UInt;
      } else {
        crc = crc >> 1;
      }
      j = j + 1;
    }
    i = i + 1;
  }
  return crc ^ 0xFFFFFFFF as UInt;
}

// === Adler32 ===
fn adler32(data: &Vec[UInt8]) -> UInt {
  const MOD_ADLER: UInt = 65521;
  var a: UInt = 1;
  var b: UInt = 0;
  var i = 0;
  let len = data.len();
  while i < len {
    a = (a + (data[i] as UInt)) % MOD_ADLER;
    b = (b + a) % MOD_ADLER;
    i = i + 1;
  }
  return (b << 16) | a;
}

// === RLE Core ===
// Format: control byte where bit 7 = 1 means run, 0 means literal
//   Run:   (control & 0x7F) + 3 repetitions of next byte  [3..130]
//   Lit:   (control & 0x7F) + 1 literal bytes follow      [1..128]

fn rle_encode(data: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  let len = data.len();
  if len == 0 {
    return result;
  }
  var pos = 0;
  while pos < len {
    var run_len = 1;
    while (pos + run_len) < len && run_len < 130 && data[pos + run_len] == data[pos] {
      run_len = run_len + 1;
    }
    if run_len >= 3 {
      var ctrl = ((run_len - 3) | 0x80) as UInt8;
      result.push(ctrl);
      result.push(data[pos]);
      pos = pos + run_len;
    } else {
      var lit_start = pos;
      var lit_count = 0;
      while (pos + lit_count) < len && lit_count < 128 {
        if (pos + lit_count + 2) < len {
          if data[pos + lit_count] == data[pos + lit_count + 1] && data[pos + lit_count] == data[pos + lit_count + 2] {
            break;
          }
        }
        lit_count = lit_count + 1;
      }
      if lit_count == 0 {
        lit_count = 1;
      }
      var ctrl = (lit_count - 1) as UInt8;
      result.push(ctrl);
      var k = 0;
      while k < lit_count {
        result.push(data[lit_start + k]);
        k = k + 1;
      }
      pos = lit_start + lit_count;
    }
  }
  return result;
}

fn rle_decode(data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  var result = Vec[UInt8].new();
  let len = data.len();
  var pos = 0;
  while pos < len {
    if pos >= len {
      return Err("RLE decode: unexpected end of data");
    }
    let ctrl = data[pos] as Int;
    pos = pos + 1;
    if ctrl >= 128 {
      let run_len = (ctrl - 128) + 3;
      if pos >= len {
        return Err("RLE decode: unexpected end of data in run");
      }
      let val = data[pos];
      pos = pos + 1;
      var k = 0;
      while k < run_len {
        result.push(val);
        k = k + 1;
      }
    } else {
      let lit_len = ctrl + 1;
      if pos + lit_len > len {
        return Err("RLE decode: unexpected end of data in literal");
      }
      var k = 0;
      while k < lit_len {
        result.push(data[pos + k]);
        k = k + 1;
      }
      pos = pos + lit_len;
    }
  }
  return Ok(result);
}

// === Gzip functions ===
// Aggregate facade: delegate to the real sublib implementations
// (xiom.compress.gzip). The earlier RLE-based duplicates trapped on
// empty input (requires: data.len() > 0) and were not gzip-compatible.
/// === Gzip functions ===
/// Aggregate facade: delegate to the real sublib implementations
/// (xiom.compress.gzip). The earlier RLE-based duplicates trapped on
/// empty input (requires: data.len() > 0) and were not gzip-compatible.
pub fn gzip_compress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str]
  ensures:  result is Ok => result.len() >= 18
{
  Ok(gzip.gzip_compress(data))
}

pub fn gzip_compress_level(data: &Vec[UInt8], level: Int) -> Result[Vec[UInt8], Str]
  ensures:  result is Ok => result.len() >= 18
{
  Ok(gzip.gzip_compress(data))
}

// Capped variant: hard ceiling on decompressed size (bomb guard).
/// Capped variant: hard ceiling on decompressed size (bomb guard).
pub fn gzip_decompress_capped(data: &Vec[UInt8], max_out: Int) -> Result[Vec[UInt8], Str]
{
  return gzip.gzip_decompress_capped(data, max_out);
}

// Capped variant: hard ceiling on decompressed size (bomb guard).
/// Capped variant: hard ceiling on decompressed size (bomb guard).
pub fn deflate_decompress_capped(data: &Vec[UInt8], max_out: Int) -> Result[Vec[UInt8], Str]
{
  return deflate.deflate_decompress_capped(data, max_out);
}

pub fn gzip_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str]
  ensures:  result is Ok => result.len() >= 0
{
  gzip.gzip_decompress(data)
}

// === Deflate / Raw ===
/// === Deflate / Raw ===
pub fn deflate_compress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str]
  ensures:  result is Ok => result.len() >= 0
{
  Ok(deflate.deflate_compress(data))
}

pub fn deflate_compress_level(data: &Vec[UInt8], level: Int) -> Result[Vec[UInt8], Str]
  ensures:  result is Ok => result.len() >= 0
{
  Ok(deflate.deflate_compress_level(data, level))
}

pub fn deflate_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str]
  ensures:  result is Ok => result.len() >= 0
{
  deflate.deflate_decompress(data)
}

// === Zlib ===
/// === Zlib ===
pub fn zlib_compress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str]
  ensures:  result is Ok => result.len() >= 6
{
  Ok(zlib.zlib_compress(data))
}

pub fn zlib_compress_level(data: &Vec[UInt8], level: Int) -> Result[Vec[UInt8], Str]
  ensures:  result is Ok => result.len() >= 6
{
  Ok(zlib.zlib_compress_level(data, level))
}

pub fn zlib_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str]
  ensures:  result is Ok => result.len() >= 0
{
  zlib.zlib_decompress(data)
}

// === Brotli ===
/// === Brotli ===
pub fn brotli_compress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str]
  ensures:  result is Ok => result.len() >= 8
{
  Ok(brotli.brotli_compress(data))
}

pub fn brotli_compress_level(data: &Vec[UInt8], quality: Int) -> Result[Vec[UInt8], Str]
  ensures:  result is Ok => result.len() >= 8
{
  Ok(brotli.brotli_compress_quality(data, quality))
}

pub fn brotli_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str]
  ensures:  result is Ok => result.len() >= 0
{
  brotli.brotli_decompress(data)
}

// === LZ4 ===
/// === LZ4 ===
pub fn lz4_compress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str]
  ensures:  result is Ok => result.len() >= 1
{
  Ok(lz4.lz4_compress(data))
}

pub fn lz4_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str]
  ensures:  result is Ok => result.len() >= 0
{
  lz4.lz4_decompress(data)
}

// === Snappy ===
/// === Snappy ===
pub fn snappy_compress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str]
  ensures:  result is Ok => result.len() >= 1
{
  Ok(snappy.snappy_compress(data))
}

pub fn snappy_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str]
  ensures:  result is Ok => result.len() >= 0
{
  snappy.snappy_decompress(data)
}

pub fn compression_ratio(original: Int, compressed: Int) -> Float64
  requires: original >= 0
  requires: compressed >= 0
  ensures:  result >= 0.0
{
  if compressed == 0 || original == 0 {
    return 1.0;
  }
  (original as Float64) / (compressed as Float64)
}

pub fn is_compressed(data: &Vec[UInt8]) -> Bool
  requires: data.len() >= 0
{
  if data.len() < 2 {
    return false;
  }
  if data[0] == 0x1F && data[1] == 0x8B {
    return true;
  }
  if data[0] == 0x78 {
    return true;
  }
  if data.len() >= 4 && data[0] == 0xCE && data[1] == 0xB2 && data[2] == 0xCF && data[3] == 0x81 {
    return true;
  }
  if data.len() >= 4 && data[0] == 0x04 && data[1] == 0x22 && data[2] == 0x4D && data[3] == 0x18 {
    return true;
  }
  return false;
}

pub fn detect_format(data: &Vec[UInt8]) -> Str
  requires: data.len() >= 0
{
  if data.len() >= 2 && data[0] == 0x1F && data[1] == 0x8B {
    return "gzip";
  }
  if data.len() >= 4 && data[0] == 0xCE && data[1] == 0xB2 && data[2] == 0xCF && data[3] == 0x81 {
    return "brotli";
  }
  if data.len() >= 1 && data[0] == 0x78 {
    return "zlib";
  }
  if data.len() >= 4 && data[0] == 0x04 && data[1] == 0x22 && data[2] == 0x4D && data[3] == 0x18 {
    return "lz4";
  }
  return "unknown";
}

// -- LZ77 --------------------------------------------------------------------

/// LZ77 compression using a simple sliding-window search.
/// Emits tokens as flat triples in a Vec[Int]: [literal_len, match_offset, match_length, ...].
/// A match_offset of 0 means no match found; literal_len bytes follow directly.
/// Window size limits the backward search distance.
/// Complexity: O(n * window), n = data length.
pub fn lz77_compress(data: &Vec[UInt8], window: Int) -> Vec[Int] {
  var result = Vec[Int].new();
  let len = data.len();
  if len == 0 {
    return result;
  };
  var pos: Int = 0;
  while pos < len {
    var best_len: Int = 0;
    var best_off: Int = 0;
    var search_start: Int = pos - window;
    if search_start < 0 { search_start = 0; };
    var si: Int = search_start;
    while si < pos {
      var match_len: Int = 0;
      while (si + match_len) < pos && (pos + match_len) < len && match_len < 255 {
        if data[si + match_len] != data[pos + match_len] {
          break;
        };
        match_len = match_len + 1;
      };
      if match_len > best_len && match_len >= 3 {
        best_len = match_len;
        best_off = pos - si;
      };
      si = si + 1;
    };
    if best_len >= 3 {
      result.push(0);
      result.push(best_off);
      result.push(best_len);
      pos = pos + best_len;
    } else {
      result.push(1);
      result.push(data[pos] as Int);
      result.push(0);
      pos = pos + 1;
    };
  };
  return result;
}

/// LZ77 decompression of token triples produced by lz77_compress.
/// Each triple: [literal_len, data, match_length_or_zero].
/// If literal_len == 0: data = match_offset, third = match_length.
/// If literal_len == 1: data = literal byte, third = 0.
/// Complexity: O(t), t = number of tokens.
pub fn lz77_decompress(tokens: &Vec[Int]) -> Result[Vec[UInt8], Str] {
  var result = Vec[UInt8].new();
  let tlen = tokens.len();
  var i: Int = 0;
  while i + 2 < tlen {
    let lit_len = tokens[i];
    let data_val = tokens[i + 1];
    let extra = tokens[i + 2];
    if lit_len == 0 {
      let off = data_val;
      let mlen = extra;
      if off == 0 || mlen <= 0 {
        return Err("LZ77 decode: invalid match token");
      };
      let dst_len = result.len();
      if off > dst_len {
        return Err("LZ77 decode: offset exceeds output length");
      };
      var k: Int = 0;
      while k < mlen {
        result.push(result[dst_len - off + (k % off)]);
        k = k + 1;
      };
    } elif lit_len == 1 {
      result.push(data_val as UInt8);
    } else {
      return Err("LZ77 decode: invalid token type");
    };
    i = i + 3;
  };
  return Ok(result);
}

// -- RLE byte-level ----------------------------------------------------------

/// Simple byte-level run-length encoding.
/// Format: [count: UInt8, byte: UInt8] for runs of identical bytes.
/// Count represents the number of repetitions (1 means 1 byte).
/// Differs from rle_encode which uses control-byte format with bit 7 markers.
/// Complexity: O(n), n = data length.
pub fn rle_encode_bytes(data: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  let len = data.len();
  if len == 0 {
    return result;
  };
  var pos: Int = 0;
  while pos < len {
    var run: Int = 1;
    while (pos + run) < len && run < 255 && data[pos + run] == data[pos] {
      run = run + 1;
    };
    result.push(run as UInt8);
    result.push(data[pos]);
    pos = pos + run;
  };
  return result;
}

// -- Huffman frequency table -------------------------------------------------

/// Builds a 256-slot frequency table for Huffman coding.
/// Each slot i contains the count of byte value i in the input.
/// Complexity: O(n), n = data length.
pub fn huffman_freqs(data: &Vec[UInt8]) -> Vec[Int] {
  var freqs = Vec[Int].new();
  var i: Int = 0;
  while i < 256 {
    freqs.push(0);
    i = i + 1;
  };
  var j: Int = 0;
  let len = data.len();
  while j < len {
    let idx = data[j] as Int;
    freqs[idx] = freqs[idx] + 1;
    j = j + 1;
  };
  return freqs;
}

// -- Gzip string wrappers ----------------------------------------------------

/// Compresses a UTF-8 string using gzip.
/// Converts Str to bytes, then wraps gzip_compress.
/// Complexity: O(n), n = string length.
pub fn compress_gzip_str(s: Str) -> Result[Vec[UInt8], Str] {
  var bytes = Vec[UInt8].new();
  var i: Int = 0;
  let slen = s.len();
  while i < slen {
    let opt = xiom.string.char_at(s, i);
    if opt.is_some {
      let code: Int = to_int_from_char(opt.value);
      bytes.push(code as UInt8);
    };
    i = i + 1;
  };
  if bytes.len() == 0 {
    return Err("compress_gzip_str: empty input");
  };
  return gzip_compress(&bytes);
}

/// Decompresses gzip data to a UTF-8 string.
/// Wraps gzip_decompress and converts the result to Str.
/// Complexity: O(n), n = compressed data length.
pub fn decompress_gzip_str(data: &Vec[UInt8]) -> Result[Str, Str] {
  let decompressed = gzip_decompress(data);
  if !decompressed.is_ok {
    return Err(decompressed.error);
  };
  let bytes = decompressed.value;
  return Ok(Str::from_utf8(bytes));
}

// -- Compression ratio alias -------------------------------------------------

/// Alias for compression_ratio. Returns original / compressed as Float64.
/// Complexity: O(1).
pub fn compress_ratio(original: Int, compressed: Int) -> Float64 {
  return compression_ratio(original, compressed);
}
