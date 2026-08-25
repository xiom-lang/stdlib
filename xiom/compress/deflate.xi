// XIOM - Compression: Deflate
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.compress.deflate

// Depends on: xiom.string

use xiom.compress.huffman;
use xiom.compress.lz77;

// ============================================================================
// DEFLATE-style compression and decompression (RFC 1951 raw stream shape).
//
// Container layout (self-describing, round-trip safe within XIOM; this is
// NOT byte-compatible with zlib's RFC 1951 stream - documented):
//   [0]    method byte: 0x00 = stored (raw copy), 0x01 = huffman + lz77
//   [1]    level (0..9)
//   [2..]  stored bytes (method 0x00) or a huffman_compress container
//          wrapping the lz77_compress token stream (method 0x01)
//
// gzip/zlib submodules wrap this payload in their container formats.
// deflate_compress_stream / brotli_decompress_stream pipe through raw file
// descriptors using fread/fwrite. Complexity: O(n * window) compress.
// ============================================================================

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn fread(buf: *UInt8, size: UInt, count: UInt, stream: *UInt8) -> UInt;
  fn fwrite(buf: *UInt8, size: UInt, count: UInt, stream: *UInt8) -> UInt;
}

/// Compress raw bytes at the default level (6): LZ77 token stream, then
/// Huffman-packed, wrapped in the container documented above.
pub fn deflate_compress(data: &Vec[UInt8]) -> Vec[UInt8] {
  return deflate_compress_level(data, 6);
}

/// Compress with an explicit level (0-9, clamped). Level 0 stores the input
/// verbatim; levels 1-9 use the huffman + lz77 pipeline.
pub fn deflate_compress_level(data: &Vec[UInt8], level: Int) -> Vec[UInt8] {
  var lvl = level;
  if lvl < 0 {
    lvl = 0;
  };
  if lvl > 9 {
    lvl = 9;
  };
  var result = Vec[UInt8].new();
  var len = data.len();
  if lvl == 0 || len <= 4 {
    result.push(0x00);
    result.push(lvl as UInt8);
    var i = 0;
    while i < len {
      result.push(data[i]);
      i = i + 1;
    }
    return result;
  }
  result.push(0x01);
  result.push(lvl as UInt8);
  var tokens = lz77.lz77_compress(data);
  var packed = huffman.huffman_compress(&tokens);
  var j = 0;
  var plen = packed.len();
  while j < plen {
    result.push(packed[j]);
    j = j + 1;
  }
  return result;
}

/// Decompress a deflate_compress / deflate_compress_level container.
/// Returns Err on truncation, an unknown method byte, or a corrupted
/// huffman/lz77 payload.
// Default output ceiling for uncapped decompression (1 GiB); passed down
// to the huffman and lz77 expanders. Capped variant accepts an explicit
// limit -- see lz77.xi for the convention.
const _DEFLATE_DEFAULT_CAP: Int = 1073741824;

pub fn deflate_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] {
  return deflate_decompress_capped(data, _DEFLATE_DEFAULT_CAP);
}

/// Decompress with a hard ceiling on output size (decompression-bomb
/// guard). The cap is enforced inside both expander stages BEFORE their
/// allocations grow.
pub fn deflate_decompress_capped(data: &Vec[UInt8], max_out: Int) -> Result[Vec[UInt8], Str] {
  var len = data.len();
  if len < 2 {
    return Err("deflate: container too short");
  };
  var method = data[0] as Int;
  if method == 0x00 {
    if len - 2 > max_out {
      return Err("deflate: output exceeds cap");
    };
    var result = Vec[UInt8].new();
    var i = 2;
    while i < len {
      result.push(data[i]);
      i = i + 1;
    }
    return Ok(result);
  }
  if method != 0x01 {
    return Err("deflate: unknown method byte");
  };
  var container = Vec[UInt8].new();
  var j = 2;
  while j < len {
    container.push(data[j]);
    j = j + 1;
  }
  var packed = huffman.huffman_decompress_capped(&container, max_out);
  var tokens = Vec[UInt8].new();
  match packed {
    Ok(v) => { tokens = v; };
    Err(e) => { return Err(e); };
  }
  var decoded = lz77.lz77_decompress_capped(&tokens, max_out);
  match decoded {
    Ok(v2) => { return Ok(v2); };
    Err(e2) => { return Err(e2); };
  }
}

/// Worst-case compressed size for `len` input bytes. Literal runs emit
/// (control, byte) pairs (2 bytes per input byte) and the huffman container
/// adds its 260-byte header plus at most ~17/8 bits per byte. O(1).
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
    return Err("deflate: empty input stream");
  };
  var compressed = deflate_compress(&input);
  var clen = compressed.len();
  unsafe {
    var written = fwrite(compressed.as_mut_ptr(), 1 as UInt, clen as UInt, writer as *UInt8);
    if written != (clen as UInt) {
      return Err("deflate: partial write to output stream");
    }
  }
  return Ok(clen);
}
