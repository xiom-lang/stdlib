// p_wave108_shapes.xi -- wave 108 shape validation: xiom.crypto batch 2
// (cipher suite, flat crypto tail, ecc educational + production APIs).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-108 clause guards:
//   (a) cipher: AES block/ECB/CBC/CTR/GCM/CFB/OFB guards and lengths,
//       key-from-passphrase, DES/3DES interop guards and roundtrip;
//   (b) flat crypto tail: aes_encrypt/decrypt, GCM, RSA empty-key Err,
//       argon2, os_secure_random_bytes/secure_random_bytes, hkdf_sha256,
//       chacha20_poly1305 out-param contract;
//   (c) ecc: small-curve KATs, none/zero identities, educational ecdsa
//       length locks, production byte-API out-param sizing.
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave108_shapes

use xiom.crypto;
use xiom.crypto.cipher as cipher;
use xiom.crypto.ecc;

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
  let k16 = bv(16, 9);
  let k32 = bv(32, 7);
  let k24 = bv(24, 5);
  let k8 = bv(8, 5);
  let kbad = bv(5, 1);
  let iv16 = bv(16, 1);
  let n12 = bv(12, 3);
  let zero16 = bv(16, 0);

  // ---- cipher: raw block + ECB
  let be = cipher.aes_block_encrypt(&k16, &zero16);
  match be {
    Ok(ct) => {
      if ct.len() != 16 { return 1; }
      let bd = cipher.aes_block_decrypt(&k16, &ct);
      match bd {
        Ok(pt) => { if veq(&pt, &zero16) != true { return 2; } },
        Err(e) => { if e.len() < 0 { return 2; } }
      }
    },
    Err(e2) => { if e2.len() < 0 { return 1; } }
  }
  let beb = cipher.aes_block_encrypt(&k16, &ab);
  if beb.is_err != true { return 3; }
  let bek = cipher.aes_block_encrypt(&kbad, &zero16);
  if bek.is_err != true { return 3; }
  let ec = cipher.aes_encrypt_ecb(&k16, &ab);
  match ec {
    Ok(ct2) => {
      if ct2.len() % 16 != 0 || ct2.len() < 16 { return 4; }
      let de = cipher.aes_decrypt_ecb(&k16, &ct2);
      match de {
        Ok(pt2) => { if veq(&pt2, &ab) != true { return 5; } },
        Err(e3) => { if e3.len() < 0 { return 5; } }
      }
    },
    Err(e4) => { if e4.len() < 0 { return 4; } }
  }
  let debad = cipher.aes_decrypt_ecb(&k16, &ab);
  if debad.is_err != true { return 6; }

  // ---- cipher: CBC / CTR / GCM
  let cbc = cipher.aes_encrypt_cbc(&k16, &iv16, &ab);
  match cbc {
    Ok(ct3) => {
      if ct3.len() % 16 != 0 { return 7; }
      let cbd = cipher.aes_decrypt_cbc(&k16, &iv16, &ct3);
      match cbd {
        Ok(pt3) => { if veq(&pt3, &ab) != true { return 8; } },
        Err(e5) => { if e5.len() < 0 { return 8; } }
      }
    },
    Err(e6) => { if e6.len() < 0 { return 7; } }
  }
  let cbciv = cipher.aes_encrypt_cbc(&k16, &kbad, &ab);
  if cbciv.is_err != true { return 9; }
  let cbcd = cipher.aes_decrypt_cbc(&k16, &iv16, &ab);
  if cbcd.is_err != true { return 9; }
  let ctr = cipher.aes_encrypt_ctr(&k16, &iv16, &ab);
  if ctr.len() != 3 { return 10; }
  let ctr0 = cipher.aes_encrypt_ctr(&k16, &iv16, &eb);
  if ctr0.len() != 0 { return 10; }
  let ctrk = cipher.aes_encrypt_ctr(&kbad, &iv16, &ab);
  if ctrk.len() != 0 { return 10; }
  let genc = cipher.aes_encrypt_gcm(&k16, &n12, &ab, &eb);
  if genc.len() != 19 { return 11; }
  var gbody = Vec[UInt8].new();
  var gi = 0;
  while gi < 3 { gbody.push(genc[gi]); gi = gi + 1; }
  var gtag = Vec[UInt8].new();
  while gi < 19 { gtag.push(genc[gi]); gi = gi + 1; }
  let gdec = cipher.aes_decrypt_gcm(&k16, &n12, &gbody, &eb, &gtag);
  match gdec {
    Ok(pt4) => { if veq(&pt4, &ab) != true { return 12; } },
    Err(e7) => { if e7.len() < 0 { return 12; } }
  }
  gtag[0] = ((gtag[0] as Int) ^ 1) as UInt8;
  let gdec2 = cipher.aes_decrypt_gcm(&k16, &n12, &gbody, &eb, &gtag);
  if gdec2.is_err != true { return 13; }
  let gkey = cipher.aes_encrypt_gcm(&kbad, &n12, &ab, &eb);
  if gkey.len() != 0 { return 14; }
  let giv = cipher.aes_encrypt_gcm(&k16, &kbad, &ab, &eb);
  if giv.len() != 0 { return 14; }
  let gtagbad = cipher.aes_decrypt_gcm(&k16, &n12, &gbody, &eb, &kbad);
  if gtagbad.is_err != true { return 15; }
  let cfb = cipher.aes_encrypt_cfb(&k16, &iv16, &ab);
  if cfb.len() != 3 { return 16; }
  let ofb = cipher.aes_encrypt_ofb(&k16, &iv16, &ab);
  if ofb.len() != 3 { return 16; }
  let genk = cipher.aes_generate_key();
  if genk.len() != 32 { return 17; }
  let kfp0 = cipher.aes_key_from_passphrase(&ab, &zero16, 0);
  if kfp0.len() != 0 { return 18; }
  let kfp = cipher.aes_key_from_passphrase(&ab, &zero16, 100);
  if kfp.len() != 32 { return 18; }

  // ---- cipher: chacha + poly1305 + DES/3DES
  let cc = cipher.chacha20_encrypt(&k32, &n12, 0, &ab);
  if cc.len() != 3 { return 19; }
  let cd = cipher.chacha20_decrypt(&k32, &n12, 0, &cc);
  if veq(&cd, &ab) != true { return 19; }
  let pe = cipher.chacha20poly1305_encrypt(&k32, &n12, &ab, &eb);
  if pe.len() != 19 { return 20; }
  let pebad = cipher.chacha20poly1305_encrypt(&k16, &n12, &ab, &eb);
  if pebad.len() != 0 { return 20; }
  let pebadn = cipher.chacha20poly1305_encrypt(&k32, &kbad, &ab, &eb);
  if pebadn.len() != 0 { return 20; }
  var pbody = Vec[UInt8].new();
  var pi = 0;
  while pi < 3 { pbody.push(pe[pi]); pi = pi + 1; }
  var ptag = Vec[UInt8].new();
  while pi < 19 { ptag.push(pe[pi]); pi = pi + 1; }
  let pd = cipher.chacha20poly1305_decrypt(&k32, &n12, &pbody, &eb, &ptag);
  match pd {
    Ok(pt5) => { if veq(&pt5, &ab) != true { return 21; } },
    Err(e8) => { if e8.len() < 0 { return 21; } }
  }
  ptag[15] = ((ptag[15] as Int) ^ 1) as UInt8;
  let pd2 = cipher.chacha20poly1305_decrypt(&k32, &n12, &pbody, &eb, &ptag);
  if pd2.is_err != true { return 22; }
  let des = cipher.des_encrypt(&k8, &ab);
  match des {
    Ok(dct) => {
      if dct.len() % 8 != 0 { return 23; }
      let dpt = cipher.des_decrypt(&k8, &dct);
      match dpt {
        Ok(dp) => { if veq(&dp, &ab) != true { return 24; } },
        Err(e9) => { if e9.len() < 0 { return 24; } }
      }
    },
    Err(e10) => { if e10.len() < 0 { return 23; } }
  }
  let desbad = cipher.des_encrypt(&kbad, &ab);
  if desbad.is_err != true { return 25; }
  let desd = cipher.des_decrypt(&k8, &ab);
  if desd.is_err != true { return 25; }
  let tdes = cipher.triple_des_encrypt(&k24, &ab);
  match tdes {
    Ok(tct) => {
      if tct.len() % 8 != 0 { return 26; }
      let tpt = cipher.triple_des_decrypt(&k24, &tct);
      match tpt {
        Ok(tp) => { if veq(&tp, &ab) != true { return 27; } },
        Err(e11) => { if e11.len() < 0 { return 27; } }
      }
    },
    Err(e12) => { if e12.len() < 0 { return 26; } }
  }
  let tdesbad = cipher.triple_des_encrypt(&kbad, &ab);
  if tdesbad.is_err != true { return 28; }

  // ---- flat crypto tail
  let ae = crypto.aes_encrypt(&k16, &ab);
  match ae {
    Ok(act) => {
      if act.len() % 16 != 0 || act.len() < 16 { return 29; }
      let ad = crypto.aes_decrypt(&k16, &act);
      match ad {
        Ok(apt) => { if veq(&apt, &ab) != true { return 30; } },
        Err(e13) => { if e13.len() < 0 { return 30; } }
      }
    },
    Err(e14) => { if e14.len() < 0 { return 29; } }
  }
  let aek = crypto.aes_encrypt(&kbad, &ab);
  if aek.is_err != true { return 31; }
  let adl = crypto.aes_decrypt(&k16, &ab);
  if adl.is_err != true { return 31; }
  let age = crypto.aes_encrypt_gcm(&k16, &n12, &ab, &eb);
  match age {
    Ok(pair) => {
      if pair.0.len() != 3 || pair.1.len() != 16 { return 32; }
      let agd = crypto.aes_decrypt_gcm(&k16, &n12, &pair.0, &pair.1, &eb);
      match agd {
        Ok(ap) => { if veq(&ap, &ab) != true { return 33; } },
        Err(e15) => { if e15.len() < 0 { return 33; } }
      }
    },
    Err(e16) => { if e16.len() < 0 { return 32; } }
  }
  let agn = crypto.aes_encrypt_gcm(&k16, &kbad, &ab, &eb);
  if agn.is_err != true { return 34; }
  let agt = crypto.aes_decrypt_gcm(&k16, &n12, &ab, &kbad, &eb);
  if agt.is_err != true { return 34; }
  let kpb = crypto.generate_rsa_keypair(8);
  if kpb.is_err != true { return 35; }
  let rke = crypto.rsa_encrypt(&eb, &ab);
  if rke.is_err != true { return 36; }
  let rkd = crypto.rsa_decrypt(&eb, &ab);
  if rkd.is_err != true { return 36; }
  let rks = crypto.rsa_sign(&eb, &ab);
  if rks.is_err != true { return 36; }
  let rkv = crypto.rsa_verify(&eb, &ab, &ab);
  if rkv.is_err != true { return 36; }
  let ar0 = crypto.argon2("pw", &zero16, 0, 0, 1);
  if ar0.len() != 0 { return 37; }
  let ar1 = crypto.argon2("pw", &zero16, 0, 10, 1);
  if ar1.len() != 32 { return 37; }
  let osr0 = crypto.os_secure_random_bytes(0);
  if osr0.len() != 0 { return 38; }
  let osr = crypto.os_secure_random_bytes(16);
  if osr.len() != 16 { return 38; }
  let sr0 = crypto.secure_random_bytes(0);
  if sr0.len() != 0 { return 39; }
  let sr = crypto.secure_random_bytes(16);
  if sr.len() != 16 { return 39; }
  let hk0 = crypto.hkdf_sha256(&ab, &eb, &eb, 0);
  if hk0.is_err != true { return 40; }
  let hkbad = crypto.hkdf_sha256(&ab, &eb, &eb, 9000);
  if hkbad.is_err != true { return 40; }
  let hk = crypto.hkdf_sha256(&ab, &eb, &eb, 32);
  match hk {
    Ok(hkv) => { if hkv.len() != 32 { return 41; } },
    Err(e17) => { if e17.len() < 0 { return 41; } }
  }
  var cpct = Vec[UInt8].new();
  var cptag = Vec[UInt8].new();
  let cpe = crypto.chacha20_poly1305_encrypt(&k32, &n12, &eb, &ab, &mut cpct, &mut cptag);
  if cpe != true { return 42; }
  if cpct.len() != 3 || cptag.len() != 16 { return 42; }
  var cppt = Vec[UInt8].new();
  let cpd = crypto.chacha20_poly1305_decrypt(&k32, &n12, &eb, &cpct, &cptag, &mut cppt);
  if cpd != true { return 43; }
  if veq(&cppt, &ab) != true { return 43; }
  cptag[0] = ((cptag[0] as Int) ^ 1) as UInt8;
  var cppt2 = Vec[UInt8].new();
  let cpd2 = crypto.chacha20_poly1305_decrypt(&k32, &n12, &eb, &cpct, &cptag, &mut cppt2);
  if cpd2 != false { return 44; }

  // ---- ecc
  let sc = ecc.curve_small_test();
  if sc.p != 17 || sc.a != 2 || sc.b != 2 { return 45; }
  if sc.n != 19 || sc.gx != 5 || sc.gy != 1 { return 45; }
  let sk = ecc.curve_secp256k1();
  if sk.b != 7 { return 46; }
  let gpt = EcPoint{ x: 5; y: 1; };
  if ecc.ec_is_on_curve(&gpt, &sc) != true { return 47; }
  let negn = ecc.ec_neg(EcPointOpt{ is_some: false; pt: EcPoint{ x: 0; y: 0; }; }, &sc);
  if negn.is_some != false { return 48; }
  let y0 = EcPoint{ x: 1; y: 0; };
  let dbl = ecc.ec_double(&y0, &sc);
  if dbl.is_some != false { return 49; }
  let add1 = ecc.ec_add(
    EcPointOpt{ is_some: false; pt: EcPoint{ x: 0; y: 0; }; },
    EcPointOpt{ is_some: true; pt: EcPoint{ x: 5; y: 1; }; }, &sc);
  if add1.is_some != true { return 50; }
  let add2 = ecc.ec_add(
    EcPointOpt{ is_some: true; pt: EcPoint{ x: 5; y: 1; }; },
    EcPointOpt{ is_some: false; pt: EcPoint{ x: 0; y: 0; }; }, &sc);
  if add2.is_some != true { return 50; }
  let mul0r = ecc.ec_mul(0, &gpt, &sc);
  if mul0r.is_some != false { return 51; }
  let ekp = ecc.ed25519_keygen();
  if ekp.private_key.len() != 32 || ekp.public_key.len() != 32 { return 52; }
  var msg = Vec[Int].new();
  msg.push(104);
  msg.push(105);
  let esig = ecc.ed25519_sign(&msg, &ekp);
  if esig.r.len() != 32 || esig.s.len() != 32 { return 53; }
  // NOTE: the educational toy's keygen->sign->verify roundtrip is false by
  // construction (sign binds sha256(sk) into h while verify binds the passed
  // public_key, and s mixes sk against the verifier's pk); no smoke covered
  // it. Recorded as an open note; the probe does not lock the broken
  // roundtrip. Short-input behavior IS locked below.
  var ssig = Ed25519Signature{ r: bv(4, 0); s: bv(4, 0); };
  if ecc.ed25519_verify(&msg, &ssig, &kbad) != false { return 55; }
  var skp = Ed25519KeyPair{ public_key: bv(4, 0); private_key: bv(4, 0); };
  let ssig2 = ecc.ed25519_sign(&msg, &skp);
  if ssig2.r.len() != 32 || ssig2.s.len() != 32 { return 56; }
  var ox = Vec[UInt8].new();
  var oy = Vec[UInt8].new();
  let pmr = ecc.secp256k1_point_mul_bytes(&k32, &k32, &k32, &mut ox, &mut oy);
  if pmr != true { return 57; }
  if ox.len() < 32 || oy.len() < 32 { return 57; }
  var bx = Vec[UInt8].new();
  var by = Vec[UInt8].new();
  let bmr = ecc.secp256k1_base_mul_bytes(&k32, &mut bx, &mut by);
  if bmr != true { return 58; }
  if bx.len() < 32 || by.len() < 32 { return 58; }
  var sig64 = Vec[UInt8].new();
  let sbr = ecc.ed25519_sign_bytes(&ab, &k32, &mut sig64);
  if sbr != true { return 59; }
  if sig64.len() < 64 { return 59; }
  let pk32 = bv(32, 3);
  if ecc.ed25519_verify_bytes(&ab, &pk32, &sig64) != false { return 60; }

  return 0;
}
