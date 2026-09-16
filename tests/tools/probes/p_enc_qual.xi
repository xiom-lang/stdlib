// p_enc_qual.xi -- encoding qualification probe (flip unblocker).
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// Replicates the load-order-sensitive surface: imports xiom.encoding PLUS the
// sibling encoding submodules (the wider e2e import shape) and exercises every
// public entry point whose loop bodies were changed from data.get(i).value to
// data[i] (+ the renamed private triplet helpers). RFC 4648 + tail-length
// vectors; returns 0 only when every check passes.
module p_enc_qual
use xiom.encoding;
use xiom.encoding.base64;
use xiom.encoding.hex;
use xiom.encoding.base32;
use xiom.encoding.percent;
use xiom.encoding.ascii85;
use xiom.encoding.punycode;
use xiom.encoding.idna;
use xiom.io;

fn main() -> Int {
  // --- base64 padded tails (1/2/3-byte remainders) ---
  if encoding.base64_encode(&encoding.utf8_encode("f")) != "Zg==" { return 1; };
  if encoding.base64_encode(&encoding.utf8_encode("fo")) != "Zm8=" { return 2; };
  if encoding.base64_encode(&encoding.utf8_encode("foo")) != "Zm9v" { return 3; };
  if encoding.base64_encode(&encoding.utf8_encode("foob")) != "Zm9vYg==" { return 4; };
  if encoding.base64_encode(&encoding.utf8_encode("fooba")) != "Zm9vYmE=" { return 5; };
  if encoding.base64_encode(&encoding.utf8_encode("foobar")) != "Zm9vYmFy" { return 6; };
  if encoding.base64_encode(&encoding.utf8_encode("")) != "" { return 7; };

  // --- base64url unpadded tails + url alphabet (0xFB 0xFF -> "-_8") ---
  if encoding.base64url_encode(&encoding.utf8_encode("f")) != "Zg" { return 8; };
  if encoding.base64url_encode(&encoding.utf8_encode("fo")) != "Zm8" { return 9; };
  if encoding.base64url_encode(&encoding.utf8_encode("foobar")) != "Zm9vYmFy" { return 10; };
  var raw = Vec[UInt8].new();
  raw.push(0xFBu8);
  raw.push(0xFFu8);
  if encoding.base64url_encode(&raw) != "-_8" { return 11; };

  // --- hex both cases + round trip ---
  let hb = encoding.utf8_encode("foobar");
  if encoding.hex_encode(&hb) != "666f6f626172" { return 12; };
  if encoding.hex_encode_upper(&hb) != "666F6F626172" { return 13; };
  match encoding.hex_decode("666f6f626172") {
    Ok(d) => { if d.len() != 6 { return 14; }; }
    Err(_) => { return 15; }
  };

  // --- url / percent (delegating legs share the loop shape) ---
  if encoding.url_encode("a b~c") != "a%20b~c" { return 16; };
  if encoding.percent_encode("a b~c") != "a%20b~c" { return 17; };
  match encoding.url_decode("a%20b+c") {
    Ok(d) => { if d != "a b c" { return 18; }; }
    Err(_) => { return 19; }
  };
  match encoding.percent_decode("a%20b+c") {
    Ok(d) => { if d != "a b c" { return 20; }; }
    Err(_) => { return 21; }
  };

  // --- utf8 decode/valid: 2/3/4-byte sequences + rejects ---
  match encoding.utf8_decode(&encoding.utf8_encode("h\u{00E9}llo")) {
    Ok(d) => { if d != "h\u{00E9}llo" { return 22; }; }
    Err(_) => { return 23; }
  };
  let emoji = encoding.utf8_encode("\u{1F600}");
  if !encoding.utf8_valid(&emoji) { return 24; };
  match encoding.utf8_decode(&emoji) {
    Ok(d) => { if d != "\u{1F600}" { return 25; }; }
    Err(_) => { return 26; }
  };
  var overlong = Vec[UInt8].new();
  overlong.push(0xC0u8);
  overlong.push(0x80u8);
  if encoding.utf8_valid(&overlong) { return 27; };
  match encoding.utf8_decode(&overlong) {
    Ok(_) => { return 28; }
    Err(_) => { }
  };
  var truncated = Vec[UInt8].new();
  truncated.push(0xF0u8);
  truncated.push(0x9Fu8);
  if encoding.utf8_valid(&truncated) { return 29; };
  var surrogate = Vec[UInt8].new();
  surrogate.push(0xEDu8);
  surrogate.push(0xA0u8);
  surrogate.push(0x80u8);
  if encoding.utf8_valid(&surrogate) { return 30; };
  var toobig = Vec[UInt8].new();
  toobig.push(0xF5u8);
  toobig.push(0x80u8);
  toobig.push(0x80u8);
  toobig.push(0x80u8);
  if encoding.utf8_valid(&toobig) { return 31; };

  // --- base32 sibling surface (same module family; guards load order) ---
  if base32.base32_encode(&encoding.utf8_encode("foo")) != "MZXW6===" { return 32; };
  match base32.base32_decode("MZXW6===") {
    Ok(d) => { if d.len() != 3 { return 33; }; }
    Err(_) => { return 34; }
  };

  io.println("P_ENC_QUAL OK");
  io.flush_stdout();
  0
}
