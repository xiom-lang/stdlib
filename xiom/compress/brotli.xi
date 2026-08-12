// XIOM - Compression: Brotli
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.compress.brotli

// Depends on: xiom.string

use xiom.compress.deflate;

// ============================================================================
// Brotli compression with quality and window controls. PARTIAL implementation
// (honest TODO(compiler)): the full RFC 7932 bit-stream -- meta-blocks,
// context modeling, static dictionary, distance-cache coding -- is NOT
// implemented. This module provides the LZ77 + Huffman framing:
//
//   [0..3]   magic CE B2 CF 81
//   [4]      quality (0..11)
//   [5]      window size exponent (10..24)
//   [6..9]   original byte length (LE, masked to 32 bits)
//   [10..]   DEFLATE-shaped payload (xiom.compress.deflate)
//
// brotli_compress / brotli_decompress round-trip within XIOM; the payload is
// decompressed via deflate_decompress and the length trailer is verified.
// Complexity: O(n * window) compress, O(n) decompress.
// ============================================================================

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn fread(buf: *UInt8, size: UInt, count: UInt, stream: *UInt8) -> UInt;
  fn fwrite(buf: *UInt8, size: UInt, count: UInt, stream: *UInt8) -> UInt;
}

/// Compress at the default quality (11) and window exponent (20).
pub fn brotli_compress(data: &Vec[UInt8]) -> Vec[UInt8] {
  return brotli_compress_quality(data, 11);
}

/// Compress with an explicit quality (0-11, clamped). The quality is recorded
/// in the header and does not change the payload shape.
pub fn brotli_compress_quality(data: &Vec[UInt8], quality: Int) -> Vec[UInt8] {
  var q = quality;
  if q < 0 {
    q = 0;
  };
  if q > 11 {
    q = 11;
  };
  return _brotli_frame(data, q, 20);
}

/// Compress with an explicit window size in bytes. The base-2 logarithm is
/// stored in the header, clamped to 10..24 (window 1KiB..16MiB).
pub fn brotli_compress_window(data: &Vec[UInt8], window: Int) -> Vec[UInt8] {
  var w = window;
  if w <= 0 {
    w = 1048576;
  };
  var exp = 10;
  while (1 << exp) < w && exp < 24 {
    exp = exp + 1;
  }
  return _brotli_frame(data, 11, exp);
}

fn _brotli_frame(data: &Vec[UInt8], quality: Int, window_exp: Int) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  result.push(0xCE);
  result.push(0xB2);
  result.push(0xCF);
  result.push(0x81);
  result.push(quality as UInt8);
  result.push(window_exp as UInt8);
  var len = data.len();
  result.push((len & 0xFF) as UInt8);
  result.push(((len >> 8) & 0xFF) as UInt8);
  result.push(((len >> 16) & 0xFF) as UInt8);
  result.push(((len >> 24) & 0xFF) as UInt8);
  var payload = deflate.deflate_compress(data);
  var i = 0;
  var plen = payload.len();
  while i < plen {
    result.push(payload[i]);
    i = i + 1;
  }
  return result;
}

/// Decompress a brotli_compress frame. Validates magic and the length
/// trailer, then decompresses the payload. Returns Err on malformed input or
/// a size mismatch.
pub fn brotli_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] {
  var len = data.len();
  if len < 10 {
    return Err("brotli: data too short for header");
  };
  if data[0] != 0xCE || data[1] != 0xB2 || data[2] != 0xCF || data[3] != 0x81 {
    return Err("brotli: invalid magic bytes");
  };
  var l0 = data[6] as Int;
  var l1 = data[7] as Int;
  var l2 = data[8] as Int;
  var l3 = data[9] as Int;
  var expected_size = l0 | (l1 << 8) | (l2 << 16) | (l3 << 24);
  var payload = Vec[UInt8].new();
  var i = 10;
  while i < len {
    payload.push(data[i]);
    i = i + 1;
  }
  var decoded = deflate.deflate_decompress(&payload);
  var decompressed = Vec[UInt8].new();
  match decoded {
    Ok(v) => { decompressed = v; };
    Err(e) => { return Err(e); };
  }
  if expected_size != decompressed.len() {
    return Err("brotli: size mismatch");
  };
  return Ok(decompressed);
}

/// Stream-decompress between two file descriptors: reads all bytes from
/// `reader`, decompresses them, writes the result to `writer`, and returns
/// the number of bytes written. Errors surface as Err.
pub fn brotli_decompress_stream(reader: Int, writer: Int) -> Result[Int, Str] {
  var input = Vec[UInt8].new();
  var done = false;
  while !done {
    unsafe {
      var buf = malloc(4096);
      var got = fread(buf, 1 as UInt, 4096 as UInt, reader as *UInt8);
      var i = 0;
      while i < got {
        input.push(buf[i]);
        i = i + 1;
      }
      free(buf);
      if got == 0 {
        done = true;
      }
    }
  }
  if input.len() == 0 {
    return Err("brotli: empty input stream");
  };
  var decoded = brotli_decompress(&input);
  var output = Vec[UInt8].new();
  match decoded {
    Ok(v) => { output = v; };
    Err(e) => { return Err(e); };
  }
  var olen = output.len();
  unsafe {
    var written = fwrite(output.as_mut_ptr(), 1 as UInt, olen as UInt, writer as *UInt8);
    if written != (olen as UInt) {
      return Err("brotli: partial write to output stream");
    }
  }
  return Ok(olen);
}
