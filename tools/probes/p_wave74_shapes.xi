// p_wave74_shapes.xi -- wave 74 shape validation: encoding + fix-first locks
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-74 clause guards on xiom.encoding (24),
// xiom.encoding.base64 (8), xiom.encoding.base32 (6), xiom.encoding.hex (9)
// and xiom.encoding.percent (8), plus the wave-74 fix-first locks
// (utf8_decode empty, base64url dangling char x2, percent '+' pins).
// Returns 0 when every case holds; no network or file I/O.

module p_wave74_shapes

use xiom.encoding;
use xiom.encoding.base64;
use xiom.encoding.base32;
use xiom.encoding.hex;
use xiom.encoding.percent;

fn _seq(n: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    v.push(i as UInt8);
    i = i + 1;
  }
  return v;
}

fn main() -> Int {
  var empty = Vec[UInt8].new();
  var b15 = Vec[UInt8].new();
  b15.push(15u8);

  // ---- fix-first locks
  match encoding.utf8_decode(&empty) {
    Ok(s) => { if s.len() != 0 { return 1; } }
    Err(_) => { return 1; }
  }
  if !encoding.utf8_valid(&empty) { return 2; }
  if !encoding.base64url_decode("AAAAA").is_err { return 3; }
  if !base64.base64url_decode("AAAAA").is_err { return 4; }
  match encoding.base64url_decode("") {
    Ok(v) => { if v.len() != 0 { return 5; } }
    Err(_) => { return 5; }
  }
  match encoding.base64url_decode("AAAA") {
    Ok(v) => { if v.len() != 3 { return 6; } }
    Err(_) => { return 6; }
  }
  match encoding.base64url_decode("AAA") {
    Ok(v) => { if v.len() != 2 { return 7; } }
    Err(_) => { return 7; }
  }
  match encoding.percent_decode("a+b") {
    Ok(s) => { if s != "a b" { return 8; } }
    Err(_) => { return 8; }
  }
  match percent.percent_decode("a+b") {
    Ok(s) => { if s != "a+b" { return 9; } }
    Err(_) => { return 9; }
  }
  match percent.percent_decode_www_form("a+b") {
    Ok(s) => { if s != "a b" { return 10; } }
    Err(_) => { return 10; }
  }

  // ---- encoding.xi base64/hex/url/utf8
  if encoding.base64_encode(&empty).len() != 0 { return 11; }
  if encoding.base64_encode(&_seq(1)).len() != 4 { return 12; }
  if encoding.base64_encode(&_seq(2)).len() != 4 { return 13; }
  if encoding.base64_encode(&_seq(3)).len() != 4 { return 14; }
  if encoding.base64_encode(&_seq(4)).len() != 8 { return 15; }
  match encoding.hex_decode("") {
    Ok(v) => { if v.len() != 0 { return 16; } }
    Err(_) => { return 16; }
  }
  if encoding.hex_encode(&_seq(2)).len() != 4 { return 17; }
  match encoding.url_decode("") {
    Ok(s) => { if s.len() != 0 { return 18; } }
    Err(_) => { return 18; }
  }
  if encoding.url_encode("a b") != "a%20b" { return 19; }
  if encoding.url_encode("").len() != 0 { return 20; }
  if encoding.utf8_char_len(65u8) != 1 { return 21; }
  if encoding.utf8_char_len(195u8) != 2 { return 22; }
  if encoding.utf8_char_len(248u8) != 1 { return 23; }
  if encoding.utf8_encode("").len() != 0 { return 24; }
  if encoding.utf8_encode("hi").len() != 2 { return 25; }
  if encoding.binary_to_text(&_seq(2), 0).len() != 4 { return 26; }
  if encoding.binary_to_text(&_seq(1), 2).len() != 2 { return 27; }
  if encoding.binary_to_text(&_seq(2), 2).len() != 3 { return 28; }
  if encoding.binary_to_text(&_seq(3), 2).len() != 4 { return 29; }
  if encoding.binary_to_text(&_seq(2), 1).len() != 4 { return 30; }
  match encoding.text_to_binary("0f", 1) {
    Ok(v) => { if v.len() != 1 { return 31; } }
    Err(_) => { return 31; }
  }
  if !encoding.text_to_binary("zz", 1).is_err { return 32; }
  if encoding.base16_encode(&_seq(2)).len() != 4 { return 33; }
  if encoding.int_to_hex(0).len() != 1 { return 34; }
  if encoding.int_to_hex(255).len() != 2 { return 35; }
  if encoding.int_to_hex(0 - 255).len() != 2 { return 36; }
  if !encoding.hex_to_int("").is_none { return 37; }
  if !encoding.hex_to_int("ff").is_some { return 38; }
  if !encoding.hex_to_int("zz").is_none { return 39; }
  if encoding.base64_encode_str("").len() != 0 { return 40; }
  if encoding.base64_encode_str("hi").len() != 4 { return 41; }
  match encoding.base64_decode_str("") {
    Ok(s) => { if s.len() != 0 { return 42; } }
    Err(_) => { return 42; }
  }
  if !encoding.base64_decode_str("!!!!").is_err { return 43; }
  if encoding.base64url_encode(&_seq(1)).len() != 2 { return 44; }
  if encoding.base64url_encode(&_seq(2)).len() != 3 { return 45; }
  if encoding.base64url_encode(&_seq(3)).len() != 4 { return 46; }
  if encoding.base32_encode(&_seq(1)).len() != 8 { return 47; }
  match encoding.base32_decode("") {
    Ok(v) => { if v.len() != 0 { return 48; } }
    Err(_) => { return 48; }
  }

  // ---- base64 module
  if base64.base64_encode(&empty).len() != 0 { return 49; }
  if base64.base64_encode(&_seq(4)).len() != 8 { return 50; }
  match base64.base64_decode("") {
    Ok(v) => { if v.len() != 0 { return 51; } }
    Err(_) => { return 51; }
  }
  if !base64.base64_decode("Zg").is_err { return 52; }
  if base64.base64_encode_str("").len() != 0 { return 53; }
  if base64.base64_encode_str("hi").len() != 4 { return 54; }
  if base64.base64_encode_padded(&_seq(4)).len() != 8 { return 55; }
  if !base64.base64_decode_padded("").is_err { return 56; }
  if !base64.base64_decode_padded("Zg===").is_err { return 57; }
  match base64.base64_decode_padded("Zg==") {
    Ok(v) => { if v.len() != 1 { return 58; } }
    Err(_) => { return 58; }
  }
  if base64.base64url_encode(&_seq(2)).len() != 3 { return 59; }
  match base64.base64url_decode("AAAA") {
    Ok(v) => { if v.len() != 3 { return 60; } }
    Err(_) => { return 60; }
  }
  match base64.base64url_decode("AAA") {
    Ok(v) => { if v.len() != 2 { return 61; } }
    Err(_) => { return 61; }
  }

  // ---- base32 module
  if base32.base32_encode(&empty).len() != 0 { return 62; }
  if base32.base32_encode(&_seq(4)).len() != 8 { return 63; }
  match base32.base32_decode("") {
    Ok(v) => { if v.len() != 0 { return 64; } }
    Err(_) => { return 64; }
  }
  match base32.base32_decode("MY======") {
    Ok(v) => { if v.len() != 1 { return 65; } }
    Err(_) => { return 65; }
  }
  if !base32.base32_decode("MZ!W6===").is_err { return 66; }
  if base32.base32hex_encode(&_seq(1)).len() != 8 { return 67; }
  match base32.base32hex_decode("CO======") {
    Ok(v) => { if v.len() != 1 { return 68; } }
    Err(_) => { return 68; }
  }
  if base32.base32_encode_str("").len() != 0 { return 69; }
  match base32.base32_decode_str("MY======") {
    Ok(s) => { if s.len() != 1 { return 70; } }
    Err(_) => { return 70; }
  }

  // ---- hex module
  if hex.hex_encode(&_seq(1)).len() != 2 { return 71; }
  match hex.hex_decode("") {
    Ok(v) => { if v.len() != 0 { return 72; } }
    Err(_) => { return 72; }
  }
  match hex.hex_decode("0f") {
    Ok(v) => { if v.len() != 1 { return 73; } }
    Err(_) => { return 73; }
  }
  if !hex.hex_decode("0").is_err { return 74; }
  if hex.hex_encode_upper(&b15) != "0F" { return 75; }
  if hex.hex_encode_str("").len() != 0 { return 76; }
  match hex.hex_decode_str("6869") {
    Ok(s) => { if s.len() != 2 { return 77; } }
    Err(_) => { return 77; }
  }
  if !hex.hex_decode_str("z").is_err { return 78; }
  if hex.hex_encode_int(0).len() != 1 { return 79; }
  if hex.hex_encode_int(255).len() != 2 { return 80; }
  if !hex.hex_decode_int("").is_err { return 81; }
  if !hex.hex_decode_int("ff").is_ok { return 82; }
  if !hex.hex_nibble_to_int(' ').is_none { return 83; }
  if hex.hex_int_to_nibble(0 - 1) != (0 as Char) { return 84; }
  if hex.hex_int_to_nibble(16) != (0 as Char) { return 85; }

  // ---- percent module
  if percent.percent_encode("a b") != "a%20b" { return 86; }
  if percent.percent_encode_component("a/b") != "a%2Fb" { return 87; }
  match percent.percent_decode("%41") {
    Ok(s) => { if s != "A" { return 88; } }
    Err(_) => { return 88; }
  }
  match percent.percent_decode_component("%41") {
    Ok(s) => { if s != "A" { return 89; } }
    Err(_) => { return 89; }
  }
  if percent.percent_encode_bytes(&_seq(1)) != "%00" { return 90; }
  match percent.percent_decode_bytes("%41") {
    Ok(v) => { if v.len() != 1 { return 91; } }
    Err(_) => { return 91; }
  }
  match percent.percent_decode_bytes("") {
    Ok(v) => { if v.len() != 0 { return 92; } }
    Err(_) => { return 92; }
  }
  if percent.percent_encode_www_form("a b") != "a+b" { return 93; }
  if percent.percent_encode_www_form("").len() != 0 { return 94; }
  if !hex.hex_nibble_to_int('\0').is_none { return 95; }

  return 0;
}
