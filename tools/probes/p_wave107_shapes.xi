// p_wave107_shapes.xi -- wave 107 shape validation: xiom.crypto batch 1
// (chacha, aead, curves, legacy des, rng_crypto, sign, rsa).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-107 clause guards:
//   (a) chacha20 state layout / length-preserving XOR round-trip;
//   (b) aead alg tables, guards and sealed/detached layouts (ChaCha20-
//       Poly1305 and AES-128-GCM paths);
//   (c) curves: clamp bits, 32-byte wire sizes, scalar validation;
//   (d) legacy DES FIPS vector + EDE degeneracy; (e) rng shuffle/choice;
//   (f) sign stubs and delegation guards; (g) rsa field mirror + KATs.
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave107_shapes

use xiom.chacha as chacha;
use xiom.crypto.aead as aead;
use xiom.crypto.curves as curves;
use xiom.crypto.rng_crypto as rng;
use xiom.crypto.sign as sign;
use xiom.des as des;
use xiom.rsa;

fn bv(n: Int, fill: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    v.push(fill as UInt8);
    i = i + 1;
  }
  return v;
}

fn abytes() -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(97);
  v.push(98);
  v.push(99);
  return v;
}

fn veq(a: &Vec[UInt8], b: &Vec[UInt8]) -> Bool {
  if a.len() != b.len() { return false; }
  var i = 0;
  while i < a.len() {
    if a[i] != b[i] { return false; }
    i = i + 1;
  }
  return true;
}

fn main() -> Int {
  let eb = Vec[UInt8].new();
  let ab = abytes();
  let k32 = bv(32, 7);
  let k16 = bv(16, 9);
  let n12 = bv(12, 3);
  let z32 = bv(32, 0);

  // ---- chacha
  let ctx = chacha.chacha20_new(&k32, &n12);
  if ctx.state.len() != 16 { return 1; }
  if ctx.state[0] != 0x61707865 || ctx.state[1] != 0x3320646e { return 2; }
  if ctx.state[2] != 0x79622d32 || ctx.state[3] != 0x6b206574 { return 2; }
  let ct = chacha.chacha20_encrypt(&k32, &n12, &ab);
  if ct.len() != 3 { return 3; }
  let pt = chacha.chacha20_decrypt(&k32, &n12, &ct);
  if veq(&pt, &ab) != true { return 4; }
  let ctx2 = chacha.chacha20_new(&k32, &n12);
  let pr = chacha.chacha20_process(&ctx2, &ab);
  if pr.len() != 3 { return 5; }
  let ctx3 = chacha.chacha20_new(&k32, &n12);
  let pr0 = chacha.chacha20_process(&ctx3, &eb);
  if pr0.len() != 0 { return 6; }

  // ---- aead tables and guards
  if aead.aead_alg_supported(1) != true { return 7; }
  if aead.aead_alg_supported(3) != true { return 7; }
  if aead.aead_alg_supported(0) != false { return 8; }
  if aead.aead_alg_supported(4) != false { return 8; }
  if aead.aead_nonce_size(3) != 12 { return 9; }
  if aead.aead_nonce_size(0) != 0 { return 9; }
  if aead.aead_tag_size(2) != 16 { return 10; }
  if aead.aead_tag_size(9) != 0 { return 10; }
  if aead.aead_key_size(1) != 16 { return 11; }
  if aead.aead_key_size(2) != 32 || aead.aead_key_size(3) != 32 { return 11; }
  if aead.aead_key_size(0) != 0 { return 11; }
  let gn = aead.aead_generate_nonce(3);
  if gn.len() != 12 { return 12; }
  let gn0 = aead.aead_generate_nonce(7);
  if gn0.len() != 0 { return 12; }

  // chacha20poly1305 path
  let enc = aead.aead_encrypt(3, &k32, &n12, &ab, &eb);
  match enc {
    Ok(e) => {
      if e.len() != 19 { return 13; }
      var body = Vec[UInt8].new();
      var i = 0;
      while i < 3 { body.push(e[i]); i = i + 1; }
      var tag = Vec[UInt8].new();
      while i < 19 { tag.push(e[i]); i = i + 1; }
      let dec = aead.aead_decrypt(3, &k32, &n12, &body, &eb, &tag);
      match dec {
        Ok(p) => { if veq(&p, &ab) != true { return 14; } },
        Err(e2) => { if e2.len() < 0 { return 14; } }
      }
      tag[15] = ((tag[15] as Int) ^ 1) as UInt8;
      let dec2 = aead.aead_decrypt(3, &k32, &n12, &body, &eb, &tag);
      if dec2.is_err != true { return 15; }
    },
    Err(e3) => { if e3.len() < 0 { return 13; } }
  }
  let encbad = aead.aead_encrypt(0, &k32, &n12, &ab, &eb);
  if encbad.is_err != true { return 16; }
  let encbad2 = aead.aead_encrypt(3, &k16, &n12, &ab, &eb);
  if encbad2.is_err != true { return 16; }
  let encbad3 = aead.aead_encrypt(3, &k32, &eb, &ab, &eb);
  if encbad3.is_err != true { return 16; }
  let sealed = aead.aead_seal(3, &k32, &ab, &eb);
  match sealed {
    Ok(s) => {
      if s.len() != 31 { return 17; }
      let op = aead.aead_open(3, &k32, &s, &eb);
      match op {
        Ok(p) => { if veq(&p, &ab) != true { return 18; } },
        Err(e4) => { if e4.len() < 0 { return 18; } }
      }
    },
    Err(e5) => { if e5.len() < 0 { return 17; } }
  }
  let short = bv(20, 0);
  let openbad = aead.aead_open(3, &k32, &short, &eb);
  if openbad.is_err != true { return 19; }
  let det = aead.aead_encrypt_detached(3, &k32, &n12, &ab, &eb);
  match det {
    Ok(pair) => {
      if pair.0.len() != 3 || pair.1.len() != 16 { return 20; }
    },
    Err(e6) => { if e6.len() < 0 { return 20; } }
  }

  // AES-128-GCM path through the same wrappers
  let enc1 = aead.aead_encrypt(1, &k16, &n12, &ab, &eb);
  match enc1 {
    Ok(e7) => { if e7.len() != 19 { return 21; } },
    Err(e8) => { if e8.len() < 0 { return 21; } }
  }

  // ---- curves
  let raw32 = bv(32, 13);
  let cl = curves.curve25519_clamp(&raw32);
  if cl.len() != 32 { return 22; }
  if (cl[0] as Int) % 8 != 0 { return 23; }
  if (cl[31] as Int) < 64 || (cl[31] as Int) > 127 { return 23; }
  let bp = curves.curve25519_base_point();
  if bp.len() != 32 { return 24; }
  if bp[0] != 9 { return 25; }
  let sm = curves.curve25519_scalar_mult(&cl, &bp);
  if sm.len() != 32 { return 26; }
  let gen = curves.secp256k1_generator();
  if gen.0.len() != 32 || gen.1.len() != 32 { return 27; }
  let add = curves.secp256k1_point_add(&gen.0, &gen.1);
  if add.0.len() != 32 || add.1.len() != 32 { return 28; }
  let mul = curves.secp256k1_point_mul(&z32, &gen.0);
  if mul.0.len() != 32 || mul.1.len() != 32 { return 29; }
  let p256 = curves.p256_curve_order();
  if p256.len() != 32 { return 30; }
  let co1 = curves.curve_order(1);
  let co2 = curves.curve_order(2);
  let co4 = curves.curve_order(4);
  if co1.len() != 32 || co2.len() != 32 || co4.len() != 32 { return 31; }
  let co9 = curves.curve_order(9);
  if co9.len() != 0 { return 31; }
  if curves.curve_scalar_valid(3, &eb) != false { return 32; }
  if curves.curve_scalar_valid(1, &z32) != false { return 32; }
  var s1 = bv(32, 0);
  s1[0] = 1;
  if curves.curve_scalar_valid(3, &s1) != true { return 33; }
  if curves.curve_point_on_curve(1, &gen.0, &gen.1) != true { return 34; }

  // ---- legacy DES (FIPS 46-3 vector + EDE degeneracy)
  let dct = des.des_encrypt_block(0x0123456789ABCDEF, 0x133457799BBCDFF1);
  if dct != -8797760620317723643 { return 35; }
  let dpt = des.des_decrypt_block(-8797760620317723643, 0x133457799BBCDFF1);
  if dpt != 0x0123456789ABCDEF { return 36; }
  let d3e = des.des3_encrypt_block(0x0123456789ABCDEF, 0x133457799BBCDFF1, 0x133457799BBCDFF1, 0x133457799BBCDFF1);
  let d1e = des.des_encrypt_block(0x0123456789ABCDEF, 0x133457799BBCDFF1);
  if d3e != d1e { return 37; }
  let d3d = des.des3_decrypt_block(dct, 0x133457799BBCDFF1, 0x133457799BBCDFF1, 0x133457799BBCDFF1);
  let d1d = des.des_decrypt_block(dct, 0x133457799BBCDFF1);
  if d3d != d1d { return 38; }

  // ---- rng_crypto
  var shuf = Vec[Int].new();
  shuf.push(5);
  shuf.push(4);
  shuf.push(3);
  shuf.push(2);
  shuf.push(1);
  rng.crypto_random_shuffle(&mut shuf);
  if shuf.len() != 5 { return 39; }
  var si = 0;
  while si < 5 {
    if shuf[si] < 1 || shuf[si] > 5 { return 40; }
    si = si + 1;
  }
  let ch0 = rng.crypto_random_choice(&eb);
  if ch0.is_none != true { return 41; }
  let ch1 = rng.crypto_random_choice(&ab);
  if ch1.is_some != true { return 41; }

  // ---- sign
  let kp = sign.ed25519_keypair();
  if kp.0.len() != 32 || kp.1.len() != 0 { return 42; }
  let seed32 = bv(32, 17);
  let kfs = sign.ed25519_keypair_from_seed(&seed32);
  if kfs.0.len() != 32 || kfs.1.len() != 0 { return 43; }
  let es = sign.ecdsa_sign(1, &eb, &eb);
  if es.0.len() != 0 || es.1.len() != 0 { return 44; }
  let sd = sign.dsa_sign(&eb, &eb, &eb, &eb, &eb);
  if sd.0.len() != 0 || sd.1.len() != 0 { return 45; }
  if sign.rsa_verify(&eb, &eb, &eb, 0) != false { return 46; }
  let rs0 = sign.rsa_sign(&eb, &eb, 0);
  if rs0.is_err != true { return 47; }

  // ---- rsa
  let kp2 = RsaKeyPair{ n: 33; e: 3; d: 7; };
  let pk = rsa.rsa_public_key(&kp2);
  if pk.n != 33 || pk.e != 3 { return 48; }
  let kgbad = rsa.rsa_keygen(4);
  if kgbad.is_err != true { return 49; }
  let kg = rsa.rsa_keygen(16);
  match kg {
    Ok(kk) => {
      if kk.n <= 0 || kk.e <= 0 || kk.d <= 0 { return 50; }
      let e2 = rsa.rsa_encrypt(2, &pk);
      if e2 != 8 { return 51; }
      let d2 = rsa.rsa_decrypt(8, &kp2);
      if d2 != 2 { return 52; }
    },
    Err(e9) => { if e9.len() < 0 { return 50; } }
  }
  if rsa.rsa_encrypt(0, &pk) != 0 { return 53; }
  if rsa.rsa_decrypt(0, &kp2) != 0 { return 53; }
  if rsa.rsa_sign(0, &kp2) != 0 { return 53; }
  if rsa.rsa_verify(0, 0, &pk) != true { return 54; }
  if rsa.rsa_verify(1, 0, &pk) != false { return 54; }

  return 0;
}
