// p_wave136_shapes.xi -- wave 136 lock: the encoding module core
// (base64/base64url/hex/base32 decoders, url/percent escapes, utf8_encode,
// hex_to_int, base64_encode_str) now decodes through the cached
// runtime-mirror `_char_at_runtime` instead of the strnlen-per-call
// char_at. Byte-exact outputs incl. the malformed/quirky paths (the
// base64_encode_str low-byte cast and the invalid-character errors).
// Returns 0 when every case holds.

module p_wave136_shapes

use xiom.string;
use xiom.encoding as enc;

fn mk2(a: Int, b: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  Str::from_utf8(v)
}

fn to_bytes(s: Str) -> Vec[UInt8] {
  var v: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  while i < string.str_len(s) {
    v.push(string.byte_at(s, i));
    i = i + 1;
  };
  v
}

fn eq_bytes(a: &Vec[UInt8], b: &Vec[UInt8]) -> Bool {
  if a.len() != b.len() { return false; }
  var i: Int = 0;
  while i < a.len() {
    if a[i] != b[i] { return false; }
    i = i + 1;
  };
  true
}

fn main() -> Int {
  // ---- base64 ----
  let d1 = enc.base64_decode("aGVsbG8=");
  match d1 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("hello")) { return 1; } },
    Err(_) => { return 2; },
  }
  let d2 = enc.base64_decode("YQ==");
  match d2 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("a")) { return 3; } },
    Err(_) => { return 4; },
  }
  let d3 = enc.base64_decode("YWI=");
  match d3 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("ab")) { return 5; } },
    Err(_) => { return 6; },
  }
  let d4 = enc.base64_decode("****");
  if d4.is_ok { return 7; }
  let d5 = enc.base64_decode(mk2(0xC3, 0xA9) + "==");
  if d5.is_ok { return 8; }
  let d6 = enc.base64_decode("");
  if !d6.is_ok { return 9; }

  // ---- base64url ----
  let u1 = enc.base64url_decode("aGVsbG8");
  match u1 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("hello")) { return 10; } },
    Err(_) => { return 11; },
  }
  let u2 = enc.base64url_decode("a");
  if u2.is_ok { return 12; }

  // ---- hex ----
  let h1 = enc.hex_decode("48656c6c6f");
  match h1 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("Hello")) { return 13; } },
    Err(_) => { return 14; },
  }
  let h2 = enc.hex_decode("zz");
  if h2.is_ok { return 15; }

  // ---- url encode/decode ----
  let e1 = enc.url_encode("a b");
  if e1 != "a%20b" { return 16; }
  let e2 = enc.url_encode(mk2(0xC3, 0xA9));
  if e2 != "%C3%A9" { return 17; }
  let e3 = enc.url_encode("a-_.~");
  if e3 != "a-_.~" { return 18; }
  let r1 = enc.url_decode("%20");
  match r1 {
    Ok(v) => { if v != " " { return 19; } },
    Err(_) => { return 20; },
  }
  let r2 = enc.url_decode("a+b");
  match r2 {
    Ok(v) => { if v != "a b" { return 21; } },
    Err(_) => { return 22; },
  }
  let r3 = enc.url_decode("%C3%A9");
  match r3 {
    Ok(v) => { if v != mk2(0xC3, 0xA9) { return 23; } },
    Err(_) => { return 24; },
  }
  let r4 = enc.url_decode("%zz");
  if r4.is_ok { return 25; }
  let r5 = enc.percent_decode("a%2Fb");
  match r5 {
    Ok(v) => { if v != "a/b" { return 26; } },
    Err(_) => { return 27; },
  }

  // ---- utf8 ----
  let f1 = enc.utf8_encode(mk2(0xC3, 0xA9));
  if !eq_bytes(&f1, &to_bytes(mk2(0xC3, 0xA9))) { return 28; }
  let f2 = enc.utf8_encode("ab");
  if !eq_bytes(&f2, &to_bytes("ab")) { return 29; }

  // ---- base32 ----
  let b1 = enc.base32_decode("MFRGG===");
  match b1 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("abc")) { return 30; } },
    Err(_) => { return 31; },
  }

  // ---- int hex ----
  let i1 = enc.hex_to_int("1f");
  if !i1.is_some { return 32; }
  if i1.value != 31 { return 33; }
  let i2 = enc.hex_to_int("zz");
  if i2.is_some { return 34; }

  // ---- base64_encode_str (incl. the low-byte cast quirk) ----
  let s1 = enc.base64_encode_str("hello");
  if s1 != "aGVsbG8=" { return 35; }
  let s2 = enc.base64_encode_str(mk2(0xC3, 0xA9));
  if s2 != "6ak=" { return 36; }  // decoded E9 + stray A9 -> two bytes

  return 0;
}
