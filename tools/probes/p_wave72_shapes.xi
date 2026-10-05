// p_wave72_shapes.xi -- wave 72 shape validation: compress formats
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-72 clause guards on xiom.compress.gzip (6),
// xiom.compress.deflate (5), xiom.compress.brotli (4),
// xiom.compress.zlib (6), xiom.compress.snappy (8) and
// xiom.compress.lz4 (10); returns 0 when every case holds. No file I/O
// (stream/file wrappers stay clause-free by design).

module p_wave72_shapes

use xiom.compress.gzip;
use xiom.compress.deflate;
use xiom.compress.brotli;
use xiom.compress.zlib;
use xiom.compress.snappy;
use xiom.compress.lz4;

fn _seq(n: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    v.push(i as UInt8);
    i = i + 1;
  }
  return v;
}

fn _digits() -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 49;
  while i <= 57 {
    v.push(i as UInt8);
    i = i + 1;
  }
  return v;
}

fn main() -> Int {
  var empty = Vec[UInt8].new();

  // ---- gzip
  if gzip.gzip_crc32(&empty) != 0 { return 1; }
  let d9 = _digits();
  if gzip.gzip_crc32(&d9) != 3421780262 { return 2; }
  if gzip.gzip_header_new(0, 255).len() != 10 { return 3; }
  if gzip.gzip_header_new(0 - 1, 300).len() != 10 { return 4; }
  if gzip.gzip_compress(&empty).len() < 20 { return 5; }
  let src3k = _seq(3000);
  if gzip.gzip_compress(&src3k).len() < 20 { return 6; }
  if !gzip.gzip_decompress(&empty).is_err { return 7; }
  if !gzip.gzip_decompress_capped(&empty, 1024).is_err { return 8; }
  let src100 = _seq(100);
  let gz100 = gzip.gzip_compress(&src100);
  if !gzip.gzip_decompress_capped(&gz100, 0 - 1).is_err { return 9; }
  if gzip.gzip_validate(&empty) { return 10; }
  let shorts = _seq(17);
  if gzip.gzip_validate(&shorts) { return 11; }
  if !gzip.gzip_validate(&gz100) { return 12; }
  match gzip.gzip_decompress(&gz100) {
    Ok(v) => { if v.len() != 100 { return 13; } }
    Err(_) => { return 13; }
  }

  // ---- deflate
  if deflate.deflate_compress(&empty).len() < 2 { return 14; }
  if deflate.deflate_compress_level(&empty, 0).len() != 5 { return 15; }
  let s3 = _seq(3);
  if deflate.deflate_compress_level(&s3, 0).len() != 8 { return 16; }
  if deflate.deflate_compress_level(&s3, 9).len() < 2 { return 17; }
  if !deflate.deflate_decompress(&empty).is_err { return 18; }
  if !deflate.deflate_decompress_capped(&empty, 64).is_err { return 19; }
  if deflate.deflate_bound(0 - 5) != 512 { return 20; }
  if deflate.deflate_bound(100) != 1012 { return 21; }
  if deflate.deflate_bound(0) != 512 { return 22; }

  // ---- brotli
  if brotli.brotli_compress(&empty).len() < 12 { return 23; }
  let s64 = _seq(64);
  if brotli.brotli_compress_quality(&s64, 0 - 3).len() < 12 { return 24; }
  if brotli.brotli_compress_quality(&s64, 99).len() < 12 { return 25; }
  if brotli.brotli_compress_window(&empty, 0).len() < 12 { return 26; }
  if !brotli.brotli_decompress(&empty).is_err { return 27; }
  let s9 = _seq(9);
  if !brotli.brotli_decompress(&s9).is_err { return 28; }
  let s50 = _seq(50);
  match brotli.brotli_decompress(&brotli.brotli_compress(&s50)) {
    Ok(v) => { if v.len() != 50 { return 29; } }
    Err(_) => { return 29; }
  }

  // ---- zlib
  if zlib.zlib_header_new(0).len() != 2 { return 30; }
  if zlib.zlib_header_new(9).len() != 2 { return 31; }
  if zlib.zlib_header_new(0 - 7).len() != 2 { return 32; }
  if zlib.zlib_adler32(&empty) != 1 { return 33; }
  if zlib.zlib_compress(&empty).len() < 8 { return 34; }
  if zlib.zlib_compress_level(&empty, 0).len() < 8 { return 35; }
  if !zlib.zlib_decompress(&empty).is_err { return 36; }
  let s5 = _seq(5);
  if !zlib.zlib_decompress(&s5).is_err { return 37; }
  if zlib.zlib_validate(&empty) { return 38; }
  if zlib.zlib_validate(&s5) { return 39; }
  let s20 = _seq(20);
  let z20 = zlib.zlib_compress(&s20);
  if !zlib.zlib_validate(&z20) { return 40; }
  let s200 = _seq(200);
  match zlib.zlib_decompress(&zlib.zlib_compress(&s200)) {
    Ok(v) => { if v.len() != 200 { return 41; } }
    Err(_) => { return 41; }
  }

  // ---- snappy
  if !snappy.snappy_uncompressed_len(&empty).is_err { return 42; }
  if snappy.snappy_validate(&empty) { return 43; }
  let s3b = _seq(3);
  if !snappy.snappy_validate(&s3b) { return 44; }
  if snappy.snappy_max_compressed_len(0 - 1) != 32 { return 45; }
  if snappy.snappy_max_compressed_len(0) != 32 { return 46; }
  if snappy.snappy_max_compressed_len(100) != 148 { return 47; }
  if snappy.snappy_compress(&empty).len() != 1 { return 48; }
  let s10 = _seq(10);
  if snappy.snappy_compress(&s10).len() < 2 { return 49; }
  if !snappy.snappy_decompress(&empty).is_err { return 50; }
  if !snappy.snappy_decompress_capped(&empty, 64).is_err { return 51; }
  if !snappy.snappy_decompress_capped(&s10, 0 - 1).is_err { return 52; }
  if snappy.snappy_compress_frame(&empty).len() != 2 { return 53; }
  if !snappy.snappy_decompress_frame(&empty).is_err { return 54; }
  var one = Vec[UInt8].new();
  one.push(0u8);
  if !snappy.snappy_decompress_frame(&one).is_err { return 55; }
  let s500 = _seq(500);
  match snappy.snappy_decompress(&snappy.snappy_compress(&s500)) {
    Ok(v) => { if v.len() != 500 { return 56; } }
    Err(_) => { return 56; }
  }

  // ---- lz4
  if lz4.lz4_compress(&empty).len() < 11 { return 57; }
  let s100b = _seq(100);
  if lz4.lz4_compress(&s100b).len() < 11 { return 58; }
  if lz4.lz4_compress_frame(&empty).len() < 11 { return 59; }
  if lz4.lz4_compress_hc(&empty).len() < 11 { return 60; }
  if lz4.lz4_bound(0 - 1) != 32 { return 61; }
  if lz4.lz4_bound(256) != 289 { return 62; }
  if !lz4.lz4_decompress(&empty).is_err { return 63; }
  let s10b = _seq(10);
  if !lz4.lz4_decompress(&s10b).is_err { return 64; }
  if !lz4.lz4_decompress_capped(&empty, 64).is_err { return 65; }
  let lzf = lz4.lz4_compress(&empty);
  if !lz4.lz4_decompress_capped(&lzf, 0 - 1).is_err { return 66; }
  if !lz4.lz4_decompress_frame(&empty).is_err { return 67; }
  if lz4.lz4_compress_block(&empty).len() != 1 { return 68; }
  if lz4.lz4_compress_hc_block(&empty).len() != 1 { return 69; }
  if !lz4.lz4_decompress_block(&empty).is_ok { return 70; }
  let s400 = _seq(400);
  match lz4.lz4_decompress(&lz4.lz4_compress(&s400)) {
    Ok(v) => { if v.len() != 400 { return 71; } }
    Err(_) => { return 71; }
  }

  return 0;
}
