// p_wave132_shapes.xi -- wave 132 lock: accelerated-path transparency --
// the per-symbol markers in docs/ACCELERATED.md plus same-build
// differential evidence: FIPS SHA-256 vectors through the dispatch-backed
// sha256, sha256 vs sha256_accelerated equality, the ct-compare dispatch
// against naive expectations, an AES-128 FIPS KAT through
// crypto.aes_encrypt/decrypt, and the dispatch-backed str_concat copy.
// The io stdin callouts (playground-4) are docs-only, no rows here.
// Returns 0 when every case holds.

module p_wave132_shapes

use xiom.string;
use xiom.crypto as scrypto;
use xiom.string.unescape as sunesc;

fn to_bytes(s: Str) -> Vec[UInt8] {
  var v: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  while i < string.str_len(s) {
    v.push(string.byte_at(s, i));
    i = i + 1;
  };
  v
}

fn hex_of(v: &Vec[UInt8]) -> Str {
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  while i < v.len() {
    let b = v[i] as Int;
    let high = b / 16;
    let low = b % 16;
    if high < 10 { out.push((48 + high) as UInt8); }
    else { out.push((87 + high) as UInt8); };
    if low < 10 { out.push((48 + low) as UInt8); }
    else { out.push((87 + low) as UInt8); };
    i = i + 1;
  };
  Str::from_utf8(out)
}

fn hex_prefix(v: &Vec[UInt8], n: Int) -> Str {
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  while i < n && i < v.len() {
    let b = v[i] as Int;
    let high = b / 16;
    let low = b % 16;
    if high < 10 { out.push((48 + high) as UInt8); }
    else { out.push((87 + high) as UInt8); };
    if low < 10 { out.push((48 + low) as UInt8); }
    else { out.push((87 + low) as UInt8); };
    i = i + 1;
  };
  Str::from_utf8(out)
}

fn main() -> Int {
  // ---- FIPS SHA-256 vectors through the dispatch-backed path ----
  let abc = to_bytes("abc");
  let h1 = scrypto.sha256_hex(&abc);
  if h1 != "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" { return 1; }
  let empty = to_bytes("");
  let h2 = scrypto.sha256_hex(&empty);
  if h2 != "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" { return 2; }

  // ---- sha256 vs sha256_accelerated (the documented pair) ----
  let a1 = scrypto.sha256(&abc);
  let a2 = scrypto.sha256_accelerated(&abc);
  if !scrypto.constant_time_compare(&a1, &a2) { return 3; }

  var big: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  while i < 1000 {
    big.push((i % 251) as UInt8);
    i = i + 1;
  };
  let b1 = scrypto.sha256(&big);
  let b2 = scrypto.sha256_accelerated(&big);
  if !scrypto.constant_time_compare(&b1, &b2) { return 4; }

  // ---- ct-compare dispatch differential ----
  let eq1 = scrypto.constant_time_compare(&abc, &abc);
  if !eq1 { return 5; }
  let xyz = to_bytes("abd");
  let eq2 = scrypto.constant_time_compare(&abc, &xyz);
  if eq2 { return 6; }
  let eq3 = scrypto.constant_time_compare(&abc, &empty);
  if eq3 { return 7; }

  // ---- AES-128 FIPS-197 C.1 KAT + roundtrip ----
  var key: Vec[UInt8] = Vec[UInt8].new();
  i = 0;
  while i < 16 {
    key.push(i as UInt8);
    i = i + 1;
  };
  var pt: Vec[UInt8] = Vec[UInt8].new();
  i = 0;
  while i < 16 {
    pt.push((i * 17) as UInt8);
    i = i + 1;
  };
  let enc = scrypto.aes_encrypt(&key, &pt);
  match enc {
    Ok(ct) => {
      // ECB + PKCS#7: one 16-byte input pads to two blocks; the first
      // block is the FIPS-197 C.1 AES-128 vector.
      if ct.len() != 32 { return 8; }
      let cth = hex_prefix(&ct, 16);
      if cth != "69c4e0d86a7b0430d8cdb78070b4c55a" { return 14; }
      let dec = scrypto.aes_decrypt(&key, &ct);
      match dec {
        Ok(back) => {
          if !scrypto.constant_time_compare(&back, &pt) { return 9; }
        },
        Err(_) => { return 10; },
      }
    },
    Err(_) => { return 11; },
  }

  // ---- dispatch-backed bulk copy (str_concat uses xiom_memcpy_dispatch) ----
  let c1 = string.str_concat("ab", string.str_concat("cd", "ef"));
  if c1 != "abcdef" { return 12; }
  var acc = "";
  i = 0;
  while i < 200 {
    acc = string.str_concat(acc, "0123456789");
    i = i + 1;
  };
  if string.str_len(acc) != 2000 { return 13; }

  // ---- \x00 escape (wave-132b audit lock): the NUL byte is dropped and
  // the scan continues; a Str cannot carry an embedded NUL.
  let n1 = sunesc.str_unescape_ascii("a\\x00b");
  if n1 != "ab" { return 15; }
  let n2 = sunesc.str_unescape_ascii("\\x00");
  if n2 != "" { return 16; }

  return 0;
}
