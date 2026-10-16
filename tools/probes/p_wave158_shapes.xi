// p_wave158_shapes.xi -- wave 158 compression lock (REL-20261015-2202 item 5
// + packages wishlist rows 23/24). Rows (0 = all hold):
//  1 -- empty input round-trips through raw deflate, gzip and zlib
//  2 -- one-byte input round-trips (raw + gzip)
//  3 -- 20 KiB all-equal run round-trips and compresses under 400 bytes
//  4 -- random 64 KiB (LCG) round-trips; chooser output is bounded (stored)
//  5 -- >32 KiB window case: match at distance ~33.7 KiB round-trips exact
//  6 -- mixed 24 KiB text: level 9 (dynamic) < level 2 (fixed); BTYPE=10
//  7 -- zlib container levels: dynamic level 9 < fixed level 2; round-trips
//  8 -- public RFC 1951 tables: boundary values + base/extra consistency
//  9 -- neutral crc32 KAT ("123456789") + gzip_crc32 coupling
// 10 -- brotli honesty (is_rfc7932 false) + custom-frame round-trip
// 11 -- accept_encoding_q: q parsing, aliases, wildcard, tolerance
// 12 -- accept_encoding_choose: RFC 9110 selection cases
// Setup failures use 20+.
//
// The third-party zlib vectors for the dynamic read path live in
// p_wave158_vectors.xi (same filter).

module p_wave158_shapes

use xiom.compress.deflate;
use xiom.compress.gzip;
use xiom.compress.zlib;
use xiom.compress.crc32;
use xiom.compress.brotli;
use xiom.compress.accept_encoding;

fn bytes_of(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(s.byte_at(i));
    i = i + 1;
  };
  return v;
}

fn eqb(a: &Vec[UInt8], b: &Vec[UInt8]) -> Bool {
  if a.len() != b.len() {
    return false;
  };
  var i = 0;
  while i < a.len() {
    if a[i] != b[i] {
      return false;
    };
    i = i + 1;
  };
  return true;
}

fn pw(k: Int) -> Int {
  var v = 1;
  var i = 0;
  while i < k {
    v = v * 2;
    i = i + 1;
  };
  return v;
}

fn lcg_bytes(n: Int, seed: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var st = seed as UInt;
  var i = 0;
  while i < n {
    st = (st * (1103515245 as UInt) + (12345 as UInt)) % (2147483648 as UInt);
    v.push(((st >> 16) & (0xFF as UInt)) as UInt8);
    i = i + 1;
  };
  return v;
}

fn phrase_bytes(n: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  let p = "The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs! 0123456789 a quick onyx goblin jumps over the lazy dwarf 9876543210\n";
  let plen = p.len();
  var i = 0;
  while i < n {
    v.push(p.byte_at(i % plen));
    i = i + 1;
  };
  return v;
}

fn all_x(n: Int, b: UInt8) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    v.push(b);
    i = i + 1;
  };
  return v;
}

fn window_case() -> Vec[UInt8] {
  // 256-byte distinctive marker, 33500 filler bytes, marker again at
  // distance 33756 (beyond 32 KiB), then a 1000-byte tail of 'b'.
  var v = Vec[UInt8].new();
  var i = 0;
  while i < 256 {
    v.push(((37 + (i * 13) % 201)) as UInt8);
    i = i + 1;
  };
  i = 0;
  while i < 33500 {
    v.push(97u8);
    i = i + 1;
  };
  i = 0;
  while i < 256 {
    v.push(((37 + (i * 13) % 201)) as UInt8);
    i = i + 1;
  };
  i = 0;
  while i < 1000 {
    v.push(98u8);
    i = i + 1;
  };
  return v;
}

fn rt_raw(want: &Vec[UInt8], code: Int) -> Int {
  let c = deflate.deflate_compress(want);
  match deflate.deflate_decompress(&c) {
    Ok(v) => { if !eqb(&v, want) { return code; }; },
    Err(_) => { return code; },
  };
  return 0;
}

fn main() -> Int {
  var empty = Vec[UInt8].new();

  // 1: empty round-trips through every container
  let e_raw = deflate.deflate_compress(&empty);
  match deflate.deflate_decompress(&e_raw) {
    Ok(v) => { if v.len() != 0 { return 1; }; },
    Err(_) => { return 1; },
  };
  let e_gz = gzip.gzip_compress(&empty);
  match gzip.gzip_decompress(&e_gz) {
    Ok(v) => { if v.len() != 0 { return 1; }; },
    Err(_) => { return 1; },
  };
  let e_zl = zlib.zlib_compress(&empty);
  match zlib.zlib_decompress(&e_zl) {
    Ok(v) => { if v.len() != 0 { return 1; }; },
    Err(_) => { return 1; },
  };

  // 2: one byte
  var one = Vec[UInt8].new();
  one.push(42u8);
  if rt_raw(&one, 2) != 0 { return 2; };
  let o_gz = gzip.gzip_compress(&one);
  match gzip.gzip_decompress(&o_gz) {
    Ok(v) => { if !eqb(&v, &one) { return 2; }; },
    Err(_) => { return 2; },
  };

  // 3: all-equal run
  let runs = all_x(20000, 121u8);
  if rt_raw(&runs, 3) != 0 { return 3; };
  let runs_c = deflate.deflate_compress(&runs);
  if runs_c.len() >= 400 { return 3; };

  // 4: random 64 KiB round-trip; the chooser must not blow up the size
  let rnd = lcg_bytes(65536, 123456789);
  let rnd_c = deflate.deflate_compress(&rnd);
  if rnd_c.len() > 66000 { return 4; };
  match deflate.deflate_decompress(&rnd_c) {
    Ok(v) => { if !eqb(&v, &rnd) { return 4; }; },
    Err(_) => { return 4; },
  };
  let rnd0 = deflate.deflate_compress_level(&rnd, 0);
  match deflate.deflate_decompress(&rnd0) {
    Ok(v) => { if !eqb(&v, &rnd) { return 4; }; },
    Err(_) => { return 4; },
  };

  // 5: >32 KiB window case
  let wc = window_case();
  if rt_raw(&wc, 5) != 0 { return 5; };

  // 6: dynamic beats fixed on mixed text; wire shape BTYPE=10
  let mixed = phrase_bytes(24000);
  let mixed_fixed = deflate.deflate_compress_level(&mixed, 2);
  let mixed_best = deflate.deflate_compress_level(&mixed, 9);
  if mixed_best.len() >= mixed_fixed.len() { return 6; };
  if mixed_best.len() < 2 { return 6; };
  if (mixed_best[0] as Int) % 8 != 5 { return 6; };
  match deflate.deflate_decompress(&mixed_best) {
    Ok(v) => { if !eqb(&v, &mixed) { return 6; }; },
    Err(_) => { return 6; },
  };
  let mixed_gz = gzip.gzip_compress(&mixed);
  match gzip.gzip_decompress(&mixed_gz) {
    Ok(v) => { if !eqb(&v, &mixed) { return 6; }; },
    Err(_) => { return 6; },
  };

  // 7: zlib container levels (dynamic level 9 < fixed level 2)
  let z9 = zlib.zlib_compress_level(&mixed, 9);
  let z2 = zlib.zlib_compress_level(&mixed, 2);
  if z9.len() >= z2.len() { return 7; };
  match zlib.zlib_decompress(&z9) {
    Ok(v) => { if !eqb(&v, &mixed) { return 7; }; },
    Err(_) => { return 7; },
  };

  // 8: public RFC 1951 tables
  let lb = deflate.deflate_length_base_table();
  let le = deflate.deflate_length_extra_table();
  let db = deflate.deflate_distance_base_table();
  let de = deflate.deflate_distance_extra_table();
  if lb.len() != 29 || le.len() != 29 || db.len() != 30 || de.len() != 30 { return 8; };
  if lb[0] != 3 || lb[4] != 7 || lb[8] != 11 { return 8; };
  if lb[24] != 131 || lb[27] != 227 || lb[28] != 258 { return 8; };
  if le[0] != 0 || le[8] != 1 || le[12] != 2 { return 8; };
  if le[16] != 3 || le[20] != 4 || le[24] != 5 || le[28] != 0 { return 8; };
  if db[0] != 1 || db[3] != 4 || db[4] != 5 || db[29] != 24577 { return 8; };
  if de[0] != 0 || de[4] != 1 || de[26] != 12 || de[28] != 13 || de[29] != 13 { return 8; };
  var ci = 0;
  // Codes 257..283 tile exactly; idx 27 (code 284) covers 227..257 only
  // because length 258 is canonically code 285 (0 extra bits).
  while ci < 27 {
    if lb[ci + 1] != lb[ci] + pw(le[ci]) { return 8; };
    ci = ci + 1;
  };
  ci = 0;
  while ci < 29 {
    if db[ci + 1] != db[ci] + pw(de[ci]) { return 8; };
    ci = ci + 1;
  };
  let fl = deflate.deflate_fixed_lit_lengths();
  let fd = deflate.deflate_fixed_dist_lengths();
  if fl.len() != 288 || fd.len() != 30 { return 8; };
  if fl[0] != 8 || fl[143] != 8 || fl[144] != 9 || fl[255] != 9 { return 8; };
  if fl[256] != 7 || fl[279] != 7 || fl[280] != 8 || fl[287] != 8 { return 8; };
  if fd[0] != 5 || fd[29] != 5 { return 8; };

  // 9: neutral crc32
  let kat = bytes_of("123456789");
  if crc32.crc32(&kat) != 3421780262 { return 9; };
  if crc32.crc32(&empty) != 0 { return 9; };
  let buf = lcg_bytes(1024, 777);
  if crc32.crc32(&buf) != ((gzip.gzip_crc32(&buf)) as Int) { return 9; };
  if crc32.crc32(&one) != ((gzip.gzip_crc32(&one)) as Int) { return 9; };

  // 10: brotli honesty + custom frame still round-trips
  if brotli.brotli_is_rfc7932() { return 10; };
  let br_src = phrase_bytes(200);
  match brotli.brotli_decompress(&brotli.brotli_compress(&br_src)) {
    Ok(v) => { if !eqb(&v, &br_src) { return 10; }; },
    Err(_) => { return 10; },
  };

  // 11: accept_encoding_q
  if accept_encoding.accept_encoding_q("gzip;q=0.5", "gzip") != 500 { return 11; };
  if accept_encoding.accept_encoding_q("gzip", "gzip") != 1000 { return 11; };
  if accept_encoding.accept_encoding_q("x-gzip;q=0.25", "gzip") != 250 { return 11; };
  if accept_encoding.accept_encoding_q("br", "gzip") != -1 { return 11; };
  if accept_encoding.accept_encoding_q("*;q=0.1", "gzip") != 100 { return 11; };
  if accept_encoding.accept_encoding_q("gzip;q=0", "gzip") != 0 { return 11; };
  if accept_encoding.accept_encoding_q("gzip;q=abc", "gzip") != 1000 { return 11; };
  if accept_encoding.accept_encoding_q("deflate;q=0.7, gzip;q=0.2", "gzip") != 200 { return 11; };
  if accept_encoding.accept_encoding_q(" gzip ; q = 0.7 ", "gzip") != 700 { return 11; };
  if accept_encoding.accept_encoding_q("gzip;q=0.001", "gzip") != 1 { return 11; };
  if accept_encoding.accept_encoding_q("", "gzip") != -1 { return 11; };
  if accept_encoding.accept_encoding_q("br;q=0.5, GZIP;q=0.8", "gzip") != 800 { return 11; };

  // 12: accept_encoding_choose
  var sup = Vec[Str].new();
  sup.push("gzip");
  sup.push("br");
  var sup1 = Vec[Str].new();
  sup1.push("gzip");
  if accept_encoding.accept_encoding_choose("gzip", &sup) != "gzip" { return 12; };
  if accept_encoding.accept_encoding_choose("", &sup) != "identity" { return 12; };
  if accept_encoding.accept_encoding_choose("x-gzip", &sup1) != "gzip" { return 12; };
  if accept_encoding.accept_encoding_choose("br;q=0.5, gzip;q=0.8", &sup) != "gzip" { return 12; };
  if accept_encoding.accept_encoding_choose("br;q=0.8, gzip;q=0.8", &sup) != "br" { return 12; };
  if accept_encoding.accept_encoding_choose("gzip;q=0, identity", &sup1) != "identity" { return 12; };
  if accept_encoding.accept_encoding_choose("gzip;q=0.5", &sup1) != "gzip" { return 12; };
  if accept_encoding.accept_encoding_choose("gzip;q=0.3, identity;q=0.5", &sup1) != "identity" { return 12; };
  if accept_encoding.accept_encoding_choose("*", &sup) != "gzip" { return 12; };
  if accept_encoding.accept_encoding_choose("*;q=0, gzip;q=0.1", &sup) != "gzip" { return 12; };
  if accept_encoding.accept_encoding_choose("*;q=0", &sup) != "" { return 12; };
  if accept_encoding.accept_encoding_choose("identity;q=0, gzip", &sup1) != "gzip" { return 12; };
  if accept_encoding.accept_encoding_choose("identity;q=0", &sup1) != "" { return 12; };
  if accept_encoding.accept_encoding_choose("zstd;q=0.9", &sup) != "identity" { return 12; };
  if accept_encoding.accept_encoding_choose("gzip;q=0, br", &sup) != "br" { return 12; };
  if accept_encoding.accept_encoding_choose("deflate, gzip", &sup1) != "gzip" { return 12; };
  if accept_encoding.accept_encoding_choose("gzip;q=0.7, br;q=0.7", &sup) != "gzip" { return 12; };
  if accept_encoding.accept_encoding_choose(", ,", &sup1) != "identity" { return 12; };
  if accept_encoding.accept_encoding_choose("GZIP", &sup1) != "gzip" { return 12; };
  if accept_encoding.accept_encoding_choose("gzip;q=1.0, *;q=0.1", &sup) != "gzip" { return 12; };

  return 0;
}
