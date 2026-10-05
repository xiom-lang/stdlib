// p_wave69_shapes.xi -- wave 69 shape validation: os (path/filetype) + rand
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-69 clause guards on xiom.path (17), xiom.os.filetype
// (22), xiom.rand (20), xiom.rand.pcg (5), xiom.rand.mt19937 (6) and
// xiom.rand.chacha (5); returns 0 when every case holds. No network or
// socket I/O; floats are probed with bands, never exact random values.

module p_wave69_shapes

use xiom.os.filetype;
use xiom.path;
use xiom.rand;
use xiom.rand.pcg;
use xiom.rand.mt19937;
use xiom.rand.chacha;

fn _mk(arr: Vec[Int]) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < arr.len() {
    v.push(arr[i] as UInt8);
    i = i + 1;
  }
  v
}

fn _u32_ok(v: Int) -> Bool {
  v >= 0 && v < 4294967296
}

fn _unit_ok(f: Float64) -> Bool {
  f >= 0.0 && f < 1.0
}

fn main() -> Int {
  // ---- filetype: EOL
  let e_empty = _mk([]);
  let e_lf = _mk([104, 105, 10]);
  let e_crlf = _mk([97, 13, 10, 98]);
  let e_cr = _mk([97, 13, 98]);
  let e_mixed = _mk([13, 10, 10]);
  if filetype.detect_eol(&e_empty) != "none" { return 1; }
  if filetype.detect_eol(&e_lf) != "lf" { return 2; }
  if filetype.detect_eol(&e_crlf) != "crlf" { return 3; }
  if filetype.detect_eol(&e_cr) != "cr" { return 4; }
  if filetype.detect_eol(&e_mixed) != "mixed" { return 5; }

  // ---- filetype: BOMs
  let bom32le = _mk([255, 254, 0, 0]);
  let bom32be = _mk([0, 0, 254, 255]);
  let bom16le = _mk([255, 254, 104, 0]);
  let bom16be = _mk([254, 255, 0, 104]);
  let bom8 = _mk([239, 187, 191, 104]);
  if filetype.detect_bom(&e_empty) != "" { return 6; }
  if filetype.detect_bom(&bom16le) != "utf-16le" { return 7; }
  if filetype.detect_bom(&bom8) != "utf-8" { return 8; }
  if filetype.detect_bom(&bom32le) != "utf-32le" { return 9; }
  if filetype.detect_bom(&bom32be) != "utf-32be" { return 10; }
  if filetype.detect_bom(&bom16be) != "utf-16be" { return 11; }
  if !filetype.has_utf8_bom(&bom8) { return 12; }
  if filetype.has_utf8_bom(&bom16le) { return 13; }
  if !filetype.has_utf16le_bom(&bom16le) { return 14; }
  if filetype.has_utf16le_bom(&bom16be) { return 15; }
  if !filetype.has_utf16be_bom(&bom16be) { return 16; }
  if filetype.has_utf16be_bom(&bom16le) { return 17; }
  if !filetype.has_utf32le_bom(&bom32le) { return 18; }
  if filetype.has_utf32le_bom(&bom32be) { return 19; }
  if !filetype.has_utf32be_bom(&bom32be) { return 20; }
  if filetype.has_utf32be_bom(&bom32le) { return 21; }

  // ---- filetype: binary/text/encoding
  let b_nul = _mk([0, 1, 2]);
  let b_txt = _mk([104, 101, 108, 108, 111]);
  let b_hi = _mk([200, 201, 202]);
  if !filetype.is_binary(&b_nul) { return 22; }
  if filetype.is_binary(&b_txt) { return 23; }
  if filetype.is_binary(&e_empty) { return 24; }
  if !filetype.is_text(&e_empty) { return 25; }
  if filetype.is_text(&b_nul) { return 26; }
  if filetype.detect_encoding(&e_empty) != "ascii" { return 27; }
  if filetype.detect_encoding(&b_nul) != "binary" { return 28; }
  if filetype.detect_encoding(&b_hi) != "utf-8" { return 29; }
  if filetype.detect_encoding(&bom16le) != "utf-16le" { return 30; }

  // ---- filetype: magic / MIME / containers
  let nine = _mk([1, 2, 3, 4, 5, 6, 7, 8, 9]);
  let png = _mk([137, 80, 78, 71, 13, 10, 26, 10]);
  let pdf = _mk([37, 80, 68, 70, 45, 49]);
  let zip = _mk([80, 75, 3, 4, 20, 0]);
  let gzip = _mk([31, 139, 8, 0]);
  let elf = _mk([127, 69, 76, 70, 2, 1]);
  let pe = _mk([77, 90, 144, 0]);
  let macho = _mk([254, 237, 250, 206, 7, 0]);
  let bmp2 = _mk([66, 77]);
  let bmp = _mk([66, 77, 16, 0]);
  let ogg = _mk([79, 103, 103, 83, 0]);
  let wav = _mk([82, 73, 70, 70, 36, 0, 0, 0, 87, 65, 86, 69]);
  if filetype.magic_number(&e_empty) != "" { return 31; }
  if filetype.magic_number(&bmp2) != "424d" { return 32; }
  let nine_magic = filetype.magic_number(&nine);
  if nine_magic.len() != 16 { return 33; }
  if filetype.detect_mime(&e_empty) != "text/plain" { return 34; }
  if filetype.detect_mime(&png) != "image/png" { return 35; }
  if filetype.detect_mime(&pdf) != "application/pdf" { return 36; }
  if filetype.detect_mime(&b_nul) != "application/octet-stream" { return 37; }
  if filetype.detect_mime(&wav) != "audio/x-wav" { return 38; }
  if filetype.mime_from_magic(&e_empty) != "application/octet-stream" { return 39; }
  if filetype.mime_from_magic(&zip) != "application/zip" { return 40; }
  if !filetype.is_image_data(&bmp) { return 41; }
  if filetype.is_image_data(&e_empty) { return 42; }
  if !filetype.is_audio_data(&ogg) { return 43; }
  if filetype.is_audio_data(&e_empty) { return 44; }
  if !filetype.is_video_data(&ogg) { return 45; }
  if filetype.is_video_data(&e_empty) { return 46; }
  if !filetype.is_pdf_data(&pdf) { return 47; }
  if filetype.is_pdf_data(&e_empty) { return 48; }
  if !filetype.is_zip_data(&zip) { return 49; }
  if filetype.is_zip_data(&e_empty) { return 50; }
  if !filetype.is_gzip_data(&gzip) { return 51; }
  if filetype.is_gzip_data(&e_empty) { return 52; }
  if !filetype.is_elf_data(&elf) { return 53; }
  if filetype.is_elf_data(&e_empty) { return 54; }
  if !filetype.is_pe_data(&pe) { return 55; }
  if filetype.is_pe_data(&e_empty) { return 56; }
  if !filetype.is_macho_data(&macho) { return 57; }
  if filetype.is_macho_data(&e_empty) { return 58; }

  // ---- path: constructors / accessors / Option presence
  if path.Path.new("a").to_str() != "a" { return 59; }
  if path.Path.new("q\\w").to_str() != "q\\w" { return 60; }
  match path.Path.new("").file_name() {
    Some(n) => { if n.len() != 0 { return 61; } }
    None => { return 61; }
  }
  if !path.Path.new("a/b/").file_name().is_none { return 62; }
  if !path.Path.new("").parent().is_none { return 63; }
  match path.Path.new("a/b").parent() {
    Some(p) => { if p.inner != "a" { return 64; } }
    None => { return 64; }
  }
  if !path.Path.new("/").parent().is_none { return 65; }
  match path.Path.new("a/b.txt").file_stem() {
    Some(s) => { if s != "b" { return 66; } }
    None => { return 66; }
  }
  match path.Path.new(".txt").file_stem() {
    Some(s) => { if s != ".txt" { return 67; } }
    None => { return 67; }
  }
  match path.Path.new("noext").file_stem() {
    Some(s) => { if s != "noext" { return 68; } }
    None => { return 68; }
  }
  match path.Path.new("").file_stem() {
    Some(s) => { if s.len() != 0 { return 69; } }
    None => { return 69; }
  }
  if !path.Path.new("").is_relative() { return 70; }
  if path.Path.new("/x").is_relative() { return 71; }
  if path.Path.new("").has_root() { return 72; }
  if !path.Path.new("/x").has_root() { return 73; }
  if path.Path.new("x").has_root() { return 74; }

  // ---- path: joins / transforms / predicates
  if path.Path.new("a").join("b").inner.len() < 1 { return 75; }
  if path.Path.new("").join("x").inner.len() < 1 { return 76; }
  if path.Path.new("x").join("").inner.len() < 1 { return 77; }
  if path.Path.new("a.txt").with_extension("md").inner != "a.md" { return 78; }
  if path.Path.new("dir/a.txt").with_extension("md").inner.len() < 1 { return 79; }
  if path.Path.new("a.txt").with_file_name("b").inner != "b" { return 80; }
  if path.Path.new("dir/a.txt").with_file_name("b").inner.len() < 1 { return 81; }
  if path.Path.new("").is_file() { return 82; }
  if !path.Path.new("./a//b").canonicalize().is_ok { return 83; }
  if !path.Path.new("").canonicalize().is_ok { return 84; }
  if !path.Path.new("abc").starts_with(path.Path.new("")) { return 85; }
  if !path.Path.new("abc").starts_with(path.Path.new("ab")) { return 86; }
  if path.Path.new("ab").starts_with(path.Path.new("abc")) { return 87; }
  if !path.Path.new("abc").ends_with(path.Path.new("")) { return 88; }
  if !path.Path.new("abc").ends_with(path.Path.new("bc")) { return 89; }
  var pb = path.PathBuf.from("a/b");
  if !pb.pop() { return 90; }
  if pb.inner != "a" { return 91; }
  if pb.pop() { return 92; }
  if pb.inner != "a" { return 93; }
  var pb_empty = path.PathBuf.from("");
  if pb_empty.pop() { return 94; }
  if path.PathBuf.from("z").as_path().inner != "z" { return 95; }
  var pb_clear = path.PathBuf.from("zz");
  pb_clear.clear();
  if pb_clear.inner.len() != 0 { return 96; }
  if path.path_separator().len() < 1 { return 97; }
  if path.path_is_absolute_str("") { return 98; }
  if !path.path_is_absolute_str("/x") { return 99; }
  if !path.path_is_absolute_str("\\x") { return 100; }
  if path.path_is_absolute_str("x") { return 101; }

  // ---- rand: core / distributions
  let r0 = rand.random();
  if r0 < 0.0 || r0 > 1.0 { return 102; }
  let ri = rand.random_int(3, 7);
  if ri < 3 || ri > 7 { return 103; }
  if rand.random_int(5, 5) != 5 { return 104; }
  let rf = rand.random_float(2.0, 3.0);
  if rf < 2.0 || rf > 3.0 { return 105; }
  if rand.random_bytes(4).len() != 4 { return 106; }
  if rand.random_bytes(0).len() != 0 { return 107; }
  if rand.random_bytes(0 - 2).len() != 0 { return 108; }
  let su = rand.sample_uniform(1.0, 2.0);
  if su < 1.0 || su > 2.0 { return 109; }
  if rand.sample_normal(0.0, 0.0) != 0.0 { return 110; }
  if rand.gaussian_box_muller(5.0, 0.0) != 5.0 { return 111; }
  if rand.sample_exponential(2.0) < 0.0 { return 112; }
  if rand.sample_bernoulli(0.0 - 1.0) { return 113; }
  if !rand.sample_bernoulli(2.0) { return 114; }
  let sb = rand.sample_binomial(4, 0.5);
  if sb < 0 || sb > 4 { return 115; }
  if rand.sample_binomial(0 - 3, 0.5) != 0 { return 116; }
  if rand.sample_poisson(3.0) < 0 { return 117; }
  if rand.sample_poisson(0.0) != 0 - 1 { return 118; }
  if rand.sample_gamma(0.0, 1.0) != 0.0 { return 119; }
  if rand.sample_gamma(0.0 - 1.0, 1.0) != 0.0 { return 120; }
  if rand.sample_beta(0.0, 1.0) != 0.0 { return 121; }
  if rand.sample_beta(1.0, 0.0 - 1.0) != 0.0 { return 122; }

  // ---- rand: pick / shuffle / uuid-adjacent
  var empty_i = Vec[Int].new();
  var items = Vec[Int].new();
  items.push(10);
  items.push(20);
  items.push(30);
  if !rand.pick(&empty_i).is_none { return 123; }
  if !rand.pick(&items).is_some { return 124; }
  if rand.pick_n(&items, 2).len() != 2 { return 125; }
  if rand.pick_n(&items, 9).len() != 3 { return 126; }
  if rand.pick_n(&items, 0).len() != 0 { return 127; }
  if rand.pick_n(&items, 0 - 1).len() != 0 { return 128; }
  var w_none = Vec[Float64].new();
  if !rand.weighted_pick(&empty_i, &w_none).is_none { return 129; }
  var w_short = Vec[Float64].new();
  w_short.push(1.0);
  if !rand.weighted_pick(&items, &w_short).is_none { return 130; }
  var w_zero = Vec[Float64].new();
  w_zero.push(0.0);
  w_zero.push(0.0);
  w_zero.push(0.0);
  if !rand.weighted_pick(&items, &w_zero).is_none { return 131; }
  var w_neg = Vec[Float64].new();
  w_neg.push(0.0 - 1.0);
  w_neg.push(2.0);
  w_neg.push(1.0);
  if !rand.weighted_pick(&items, &w_neg).is_none { return 132; }
  var w_ok = Vec[Float64].new();
  w_ok.push(1.0);
  w_ok.push(1.0);
  w_ok.push(1.0);
  if !rand.weighted_pick(&items, &w_ok).is_some { return 133; }
  let xs0 = rand.Xorshift64.new(0);
  if xs0.state == 0 { return 134; }
  let xs5 = rand.Xorshift64.new(5);
  if xs5.state != 5 { return 135; }
  if !rand.random_choice(&empty_i).is_none { return 136; }
  if !rand.random_choice(&items).is_some { return 137; }
  var sv = Vec[Int].new();
  sv.push(1);
  sv.push(2);
  rand.random_shuffle(&mut sv);
  if sv.len() != 2 { return 138; }
  let rfrac = rand.random_fraction();
  if rfrac < 0.0 || rfrac > 1.0 { return 139; }
  let sr0 = rand.StdRng.from_seed(0);
  if sr0.state == 0 { return 140; }
  let sr42 = rand.StdRng.from_seed(42);
  if sr42.state != 42 { return 141; }
  if rand.random_bytes_crypto(4).len() != 4 { return 142; }
  if rand.random_bytes_crypto(0).len() != 0 { return 143; }

  // ---- rand.pcg
  var pg = pcg.pcg_new();
  if pg.state == 0 { return 144; }
  if pg.inc == 0 { return 145; }
  let pg2 = pcg.pcg_from_seed(7 as UInt64);
  if pg2.state == 0 { return 146; }
  let pgi = pcg.pcg_next_int(&mut pg);
  if !_u32_ok(pgi) { return 147; }
  let pgf = pcg.pcg_next_float(&mut pg);
  if !_unit_ok(pgf) { return 148; }
  let pgb = pcg.pcg_next_bounded(&mut pg, 10);
  if pgb < 0 || pgb >= 10 { return 149; }
  if pcg.pcg_next_bounded(&mut pg, 0) != 0 { return 150; }
  if pcg.pcg_next_bounded(&mut pg, 0 - 3) != 0 { return 151; }

  // ---- rand.mt19937
  var mt = mt19937.mt19937_new();
  if mt.state.len() != 624 { return 152; }
  if mt.index != 624 { return 153; }
  var mt2 = mt19937.mt19937_from_seed(1 as UInt32);
  if mt2.state.len() != 624 { return 154; }
  let mti = mt19937.mt19937_next_int(&mut mt);
  if !_u32_ok(mti) { return 155; }
  let mtf = mt19937.mt19937_next_float(&mut mt);
  if !_unit_ok(mtf) { return 156; }
  let mtb = mt19937.mt19937_next_bounded(&mut mt, 5);
  if mtb < 0 || mtb >= 5 { return 157; }
  if mt19937.mt19937_next_bounded(&mut mt, 0) != 0 { return 158; }
  mt19937.mt19937_reseed(&mut mt2, 2 as UInt32);
  if mt2.state.len() != 624 { return 159; }
  if mt2.index != 624 { return 160; }

  // ---- rand.chacha
  var ch = chacha.chacha_rng_new();
  if ch.state.len() != 16 { return 161; }
  if ch.pos != 0 { return 162; }
  var ch2 = chacha.chacha_rng_from_seed(9 as UInt64);
  if ch2.state.len() != 16 { return 163; }
  let chi = chacha.chacha_rng_next_int(&mut ch);
  if !_u32_ok(chi) { return 164; }
  let chf = chacha.chacha_rng_next_float(&mut ch);
  if !_unit_ok(chf) { return 165; }
  let chb = chacha.chacha_rng_next_bounded(&mut ch, 5);
  if chb < 0 || chb >= 5 { return 166; }
  if chacha.chacha_rng_next_bounded(&mut ch, 0) != 0 { return 167; }

  return 0;
}
