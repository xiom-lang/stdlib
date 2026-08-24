// kat_crypto_chacha20poly1305_rfc8439.xi -- RFC 8439 section 2.8.2 AEAD vector
// Keystream correctness (ciphertext) and AAD-inclusion correctness (tag) are
// pinned independently: ct proves the ChaCha20 stream, tag proves Poly1305
// covered the AAD. Round-trip + tamper rejection close the loop.
module kat_crypto_chacha20poly1305_rfc8439
use xiom.crypto;
use xiom.io;
use xiom.convert;
use xiom.encoding.hex;

fn hx(s: Str) -> Vec[UInt8] {
  match hex.hex_decode(s) {
    Ok(v) => { return v; },
    Err(e) => { io.println("bad hex literal: " + e); return Vec[UInt8].new(); },
  }
}

fn bytes_of(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(s.byte_at(i));
    i += 1;
  }
  return v;
}

fn main() -> Int {
  var key = hx("808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f");
  var nonce = hx("070000004041424344454647");
  var aad = hx("50515253c0c1c2c3c4c5c6c7");
  // RFC 8439 2.8.2 plaintext (ASCII):
  // "Ladies and Gentlemen of the class of '99: If I could offer you only
  //  one tip for the future, sunscreen would be it."
  var plain = bytes_of("Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it.");

  var want_ct = hx("d31a8d34648e60db7b86afbc53ef7ec2a4aded51296e08fea9e2b5a736ee62d63dbea45e8ca9671282fafb69da92728b1a71de0a9e060b2905d6a5b67ecd3b3692ddbd7f2d778b8c9803aee328091b58fab324e4fad675945585808b4831d7bc3ff4def08e4b7a9de576d26586cec64b6116");
  var want_tag = hx("1ae10b594f09e26a7e902ecbd0600691");

  if key.len() != 32 || nonce.len() != 12 || aad.len() != 12 || plain.len() != 114 {
    io.println("vector construction wrong");
    return 1;
  }

  var ct = Vec[UInt8].new();
  var tg = Vec[UInt8].new();
  if !crypto.chacha20_poly1305_encrypt(&key, &nonce, &aad, &plain, &mut ct, &mut tg) {
    io.println("encrypt returned false");
    return 2;
  }

  if ct.len() != want_ct.len() {
    io.println("ct len mismatch");
    return 3;
  }
  var i = 0;
  while i < want_ct.len() {
    if ct[i] != want_ct[i] {
      io.println("ct byte mismatch at index " + convert.int_to_string(i));
      return 4;
    }
    i += 1;
  }

  if tg.len() != want_tag.len() { io.println("tag len mismatch"); return 5; }
  i = 0;
  while i < want_tag.len() {
    if tg[i] != want_tag[i] {
      io.println("tag mismatch: got " + hex.hex_encode(&tg));
      return 6;
    }
    i += 1;
  }

  // round trip: our own ciphertext must decrypt back to the plaintext
  var rt = Vec[UInt8].new();
  if !crypto.chacha20_poly1305_decrypt(&key, &nonce, &aad, &ct, &tg, &mut rt) {
    io.println("decrypt(encrypt) returned false");
    return 7;
  }
  if rt.len() != plain.len() { io.println("rt len mismatch"); return 8; }
  i = 0;
  while i < plain.len() {
    if rt[i] != plain[i] { io.println("rt byte mismatch"); return 9; }
    i += 1;
  }

  // tamper: flipping one tag bit MUST fail decryption
  var bad_tg = Vec[UInt8].new();
  i = 0;
  while i < tg.len() {
    if i == 0 && tg[i] == 0u8 { bad_tg.push(1u8); } else {
      if i == 0 { bad_tg.push(0u8); } else { bad_tg.push(tg[i]); }
    }
    i += 1;
  }
  var out2 = Vec[UInt8].new();
  if crypto.chacha20_poly1305_decrypt(&key, &nonce, &aad, &ct, &bad_tg, &mut out2) {
    io.println("decrypt accepted tampered tag");
    return 10;
  }

  io.println("kat_crypto_chacha20poly1305_rfc8439 OK");
  return 0;
}
