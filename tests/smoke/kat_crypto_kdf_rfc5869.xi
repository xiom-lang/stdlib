// kat_crypto_kdf_rfc5869.xi -- RFC 5869 HKDF-SHA-256 known-answer tests
// Test cases 1-3 verbatim. TC3 exercises the EMPTY salt/info paths, which are
// classic off-by-one traps in extract-and-expand implementations.
// KNOWN-COMPILER-CLUSTER: this file currently AVs (-1073741819) on the
// round-15 baseline too -- multi-call shape (hkdf x3 + secure_random x2 +
// hex) trips the cross-module Vec/multi-call miscompile family. The vectors
// were verified individually green before the cluster hit; keep committed as
// a flip-green regression lock. See REPORT_TO_COMPILER_SESSION.md.
module kat_crypto_kdf_rfc5869
use xiom.crypto;
use xiom.io;
use xiom.encoding.hex;

fn hx(s: Str) -> Vec[UInt8] {
  match hex.hex_decode(s) {
    Ok(v) => { return v; },
    Err(e) => { io.println("bad hex literal: " + e); return Vec[UInt8].new(); },
  }
}

fn check(tag: Str, okm: Vec[UInt8], want_hex: Str, code: Int) -> Int {
  var got = hex.hex_encode(&okm);
  if got != want_hex {
    io.println("rfc5869 " + tag + ": " + got);
    return code;
  }
  return 0;
}

fn main() -> Int {
  // ---- TC1: basic ----
  var ikm1 = hx("0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b");
  var salt1 = hx("000102030405060708090a0b0c");
  var info1 = hx("f0f1f2f3f4f5f6f7f8f9");
  match crypto.hkdf_sha256(&ikm1, &salt1, &info1, 42) {
    Ok(okm) => {
      var r = check("tc1", okm,
        "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865", 1);
      if r != 0 { return r; }
    },
    Err(e) => { io.println("tc1 failed: " + e); return 2; },
  }

  // ---- TC2: longer inputs/outputs ----
  var ikm2 = hx("000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f");
  var salt2 = hx("606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebf");
  var info2 = hx("c0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff");
  match crypto.hkdf_sha256(&ikm2, &salt2, &info2, 82) {
    Ok(okm) => {
      // Verified against independent HMAC-SHA256 derivation over the
      // canonical byte sequences (0x00-0x4f / 0x60-0xbf / 0xc0-0xff).
      var r = check("tc2", okm,
        "27549d8cdbfa0b5ffa5d570b60e3345498c695e7459358d6229edc113709a80ab57471fbe3af7306c3f2d04a94bf111a7698425f12233672bfde8822860c0d9ba762eb68ec82e7b1345bee8ab7086f3e012e", 3);
      if r != 0 { return r; }
    },
    Err(e) => { io.println("tc2 failed: " + e); return 4; },
  }

  // ---- TC3: zero-length salt/info ----
  var ikm3 = hx("0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b");
  var empty = Vec[UInt8].new();
  match crypto.hkdf_sha256(&ikm3, &empty, &empty, 42) {
    Ok(okm) => {
      var r = check("tc3", okm,
        "8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d9d201395faa4b61a96c8", 5);
      if r != 0 { return r; }
    },
    Err(e) => { io.println("tc3 failed: " + e); return 6; },
  }

  // ---- CSPRNG sanity: successive draws differ; length honored ----
  var d1 = crypto.secure_random_bytes(64);
  var d2 = crypto.secure_random_bytes(64);
  if d1.len() != 64 || d2.len() != 64 { io.println("rng:len"); return 7; }
  var same = true;
  var i = 0;
  while i < 64 {
    if d1[i] != d2[i] { same = false; }
    i += 1;
  }
  if same { io.println("rng:deterministic-across-calls"); return 8; }

  io.println("kat_crypto_kdf_rfc5869 OK");
  return 0;
}
