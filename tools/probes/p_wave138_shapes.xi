// p_wave138_shapes.xi -- wave 138 lock: the encoding SUBMODULES
// (base64 / base32 / hex / percent / punycode / idna / ascii85) now read
// through cached (base, len) views + the function-shaped raw-byte and
// runtime-mirror decode helpers instead of the strnlen-per-call
// string.byte_at / s.char_at accessors. Byte-exact outputs incl. the
// multibyte, padding, malformed-escape and delimiter paths.
// Returns 0 when every case holds.

module p_wave138_shapes

use xiom.string;
use xiom.encoding.base64;
use xiom.encoding.base32;
use xiom.encoding.hex;
use xiom.encoding.percent;
use xiom.encoding.punycode;
use xiom.encoding.idna;
use xiom.encoding.ascii85;

fn mk2(a: Int, b: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  Str::from_utf8(v)
}

fn mk3(a: Int, b: Int, c: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  v.push(c as UInt8);
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

fn zeros4() -> Vec[UInt8] {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(0 as UInt8);
  v.push(0 as UInt8);
  v.push(0 as UInt8);
  v.push(0 as UInt8);
  v
}

fn main() -> Int {
  // ---- base64 ----
  let d1 = base64.base64_decode("aGVsbG8=");
  match d1 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("hello")) { return 1; } },
    Err(_) => { return 2; },
  }
  let d2 = base64.base64_decode("YQ==");
  match d2 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("a")) { return 3; } },
    Err(_) => { return 4; },
  }
  let d3 = base64.base64_decode("YWI=");
  match d3 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("ab")) { return 5; } },
    Err(_) => { return 6; },
  }
  let d4 = base64.base64_decode("****");
  if d4.is_ok { return 7; }
  let d5 = base64.base64_decode("YQ=");
  if d5.is_ok { return 8; }
  let d6 = base64.base64_decode("AA=A");
  if d6.is_ok { return 9; }
  let d7 = base64.base64_decode("");
  if !d7.is_ok { return 10; }
  let d8 = base64.base64_decode_padded("Zg==");
  match d8 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("f")) { return 11; } },
    Err(_) => { return 12; },
  }
  let d9 = base64.base64_decode_padded("Zg");
  if d9.is_ok { return 13; }
  let d10 = base64.base64_decode_padded("====");
  if d10.is_ok { return 14; }
  if base64.base64_encode(&to_bytes("hello")) != "aGVsbG8=" { return 15; }
  if base64.base64_encode_padded(&to_bytes("f")) != "Zg==" { return 16; }
  if base64.base64_encode_str("hello") != "aGVsbG8=" { return 17; }
  if base64.base64_encode_str(mk2(0xC3, 0xA9)) != "w6k=" { return 18; }
  let d11 = base64.base64_decode_str("aGVsbG8=");
  match d11 {
    Ok(v) => { if v != "hello" { return 19; } },
    Err(_) => { return 20; },
  }
  let u1 = base64.base64url_decode("aGVsbG8");
  match u1 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("hello")) { return 21; } },
    Err(_) => { return 22; },
  }
  let u2 = base64.base64url_decode("a");
  if u2.is_ok { return 23; }
  if base64.base64url_encode(&to_bytes("hello")) != "aGVsbG8" { return 24; }

  // ---- base32 ----
  let b1 = base32.base32_decode("MZXW6===");
  match b1 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("foo")) { return 25; } },
    Err(_) => { return 26; },
  }
  let b2 = base32.base32_decode("MY======");
  match b2 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("f")) { return 27; } },
    Err(_) => { return 28; },
  }
  let b3 = base32.base32_decode("mzxw6===");
  match b3 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("foo")) { return 29; } },
    Err(_) => { return 29; },
  }
  let b4 = base32.base32_decode("MZXW6Y");
  if b4.is_ok { return 30; }
  if base32.base32_encode(&to_bytes("foo")) != "MZXW6===" { return 31; }
  if base32.base32hex_encode(&to_bytes("foo")) != "CPNMU===" { return 32; }
  let b5 = base32.base32hex_decode("CPNMU===");
  match b5 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("foo")) { return 33; } },
    Err(_) => { return 34; },
  }
  if base32.base32_encode_str("hello") != base32.base32_encode(&to_bytes("hello")) { return 35; }
  let b6 = base32.base32_decode_str("NBSWY3DP");
  match b6 {
    Ok(v) => { if v != "hello" { return 36; } },
    Err(_) => { return 37; },
  }

  // ---- hex ----
  let h1 = hex.hex_decode("48656c6c6f");
  match h1 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("Hello")) { return 38; } },
    Err(_) => { return 39; },
  }
  let h2 = hex.hex_decode("4");
  if h2.is_ok { return 40; }
  let h3 = hex.hex_decode("zz");
  if h3.is_ok { return 41; }
  if hex.hex_encode(&to_bytes("Hello")) != "48656c6c6f" { return 42; }
  if hex.hex_encode_upper(&to_bytes("AB")) != "4142" { return 43; }
  let h4 = hex.hex_decode_int("1f");
  if !h4.is_ok { return 44; }
  if h4.value != 31 { return 45; }
  let h5 = hex.hex_decode_int("zz");
  if h5.is_ok { return 46; }
  let h6 = hex.hex_decode_int("");
  if h6.is_ok { return 47; }
  if hex.hex_encode_int(31) != "1f" { return 48; }
  if hex.hex_encode_int(0) != "0" { return 49; }
  if hex.hex_encode_str("Hello") != "48656c6c6f" { return 50; }
  if hex.hex_encode_str(mk2(0xC3, 0xA9)) != "c3a9" { return 51; }
  let h7 = hex.hex_decode_str("48656c6c6f");
  match h7 {
    Ok(v) => { if v != "Hello" { return 52; } },
    Err(_) => { return 53; },
  }
  let h8 = hex.hex_decode_str("zz");
  if h8.is_ok { return 54; }
  let h9 = hex.hex_nibble_to_int('f');
  if !h9.is_some { return 55; }
  if h9.value != 15 { return 56; }
  if hex.hex_int_to_nibble(15) != 'f' { return 57; }

  // ---- percent ----
  if percent.percent_encode("a b") != "a%20b" { return 58; }
  if percent.percent_encode(mk2(0xC3, 0xA9)) != "%C3%A9" { return 59; }
  if percent.percent_encode("a-_.~") != "a-_.~" { return 60; }
  let p1 = percent.percent_decode("%20");
  match p1 {
    Ok(v) => { if v != " " { return 61; } },
    Err(_) => { return 62; },
  }
  let p2 = percent.percent_decode("a%2Fb");
  match p2 {
    Ok(v) => { if v != "a/b" { return 63; } },
    Err(_) => { return 64; },
  }
  let p3 = percent.percent_decode("%zz");
  if p3.is_ok { return 65; }
  let p4 = percent.percent_decode("%2");
  if p4.is_ok { return 66; }
  let p5 = percent.percent_decode("%C3%A9");
  match p5 {
    Ok(v) => { if v != mk2(0xC3, 0xA9) { return 67; } },
    Err(_) => { return 68; },
  }
  let p6 = percent.percent_decode_bytes("%00");
  match p6 {
    Ok(v) => {
      if v.len() != 1 { return 69; }
      if v[0] != 0 as UInt8 { return 70; }
    },
    Err(_) => { return 71; },
  }
  let p7 = percent.percent_decode_bytes("ab%2F");
  match p7 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("ab/")) { return 72; } },
    Err(_) => { return 73; },
  }
  if percent.percent_encode_bytes(&to_bytes("a b")) != "a%20b" { return 74; }
  var slash: Vec[UInt8] = Vec[UInt8].new();
  slash.push(47 as UInt8);
  if percent.percent_encode_bytes(&slash) != "%2F" { return 75; }
  if percent.percent_encode_www_form("a b") != "a+b" { return 76; }
  let p8 = percent.percent_decode_www_form("a+b");
  match p8 {
    Ok(v) => { if v != "a b" { return 77; } },
    Err(_) => { return 78; },
  }
  let p9 = percent.percent_decode_www_form("%C3%A9");
  match p9 {
    Ok(v) => { if v != mk2(0xC3, 0xA9) { return 79; } },
    Err(_) => { return 80; },
  }
  let p10 = percent.percent_decode_component("%20");
  match p10 {
    Ok(v) => { if v != " " { return 81; } },
    Err(_) => { return 82; },
  }
  if percent.percent_encode_component("a b") != "a%20b" { return 83; }

  // ---- punycode ----
  let y1 = punycode.punycode_encode("b" + mk2(0xC3, 0xBC) + "cher");
  match y1 {
    Ok(v) => { if v != "bcher-kva" { return 84; } },
    Err(_) => { return 85; },
  }
  let y2 = punycode.punycode_decode("bcher-kva");
  match y2 {
    Ok(v) => { if v != "b" + mk2(0xC3, 0xBC) + "cher" { return 86; } },
    Err(_) => { return 87; },
  }
  let y3 = punycode.punycode_encode_domain("b" + mk2(0xC3, 0xBC) + "cher.example");
  match y3 {
    Ok(v) => { if v != "xn--bcher-kva.example" { return 88; } },
    Err(_) => { return 89; },
  }
  let y4 = punycode.punycode_decode_domain("xn--bcher-kva.example");
  match y4 {
    Ok(v) => { if v != "b" + mk2(0xC3, 0xBC) + "cher.example" { return 90; } },
    Err(_) => { return 91; },
  }
  let y5 = punycode.punycode_decode("bcher-!!");
  if y5.is_ok { return 92; }
  let y6 = punycode.punycode_encode("");
  match y6 {
    Ok(v) => { if v != "" { return 93; } },
    Err(_) => { return 94; },
  }
  let y7 = punycode.punycode_encode_domain("plain.example");
  match y7 {
    Ok(v) => { if v != "plain.example" { return 95; } },
    Err(_) => { return 96; },
  }

  // ---- idna ----
  let n1 = idna.idna_to_ascii("b" + mk2(0xC3, 0xBC) + "cher.example");
  match n1 {
    Ok(v) => { if v != "xn--bcher-kva.example" { return 97; } },
    Err(_) => { return 98; },
  }
  let n2 = idna.idna_to_unicode("xn--bcher-kva.example");
  match n2 {
    Ok(v) => { if v != "b" + mk2(0xC3, 0xBC) + "cher.example" { return 99; } },
    Err(_) => { return 100; },
  }
  if !idna.idna_is_valid("xn--bcher-kva.example") { return 101; }
  if idna.idna_is_valid("bad_label.example") { return 102; }
  if idna.idna_is_valid("") { return 103; }
  let n3 = idna.idna_uts46_normalize("ABC");
  match n3 {
    Ok(v) => { if v != "abc" { return 104; } },
    Err(_) => { return 105; },
  }
  let n4 = idna.idna_uts46_normalize(mk2(0xC3, 0xA9));
  match n4 {
    Ok(v) => { if v != mk2(0xC3, 0xA9) { return 106; } },
    Err(_) => { return 107; },
  }
  let n5 = idna.idna_uts46_normalize(mk3(0xEF, 0xBC, 0xA1));
  match n5 {
    Ok(v) => { if v != "A" { return 108; } },
    Err(_) => { return 109; },
  }
  let n6 = idna.idna_uts46_normalize(mk2(0x01, 0x41));
  if n6.is_ok { return 110; }
  let n7 = idna.idna_nameprep("ABC");
  match n7 {
    Ok(v) => { if v != "abc" { return 111; } },
    Err(_) => { return 112; },
  }
  let n8 = idna.idna_nameprep(mk2(0x20, 0x41));
  if n8.is_ok { return 113; }
  if !idna.idna_is_bidi_valid("abc") { return 114; }
  if !idna.idna_is_bidi_valid(mk3(0xD7, 0x90, 0xD7) + mk3(0x91, 0xD7, 0x92)) { return 115; }
  let n9 = idna.idna_to_ascii("");
  if n9.is_ok { return 116; }
  let labs = idna.idna_split_labels("a.b");
  if labs.len() != 2 { return 117; }
  if idna.idna_join_labels(&labs) != "a.b" { return 118; }

  // ---- ascii85 ----
  if ascii85.ascii85_encode(&zeros4()) != "z" { return 119; }
  let a1 = ascii85.ascii85_decode("z");
  match a1 {
    Ok(v) => { if !eq_bytes(&v, &zeros4()) { return 120; } },
    Err(_) => { return 121; },
  }
  let a2 = ascii85.ascii85_decode("v");
  if a2.is_ok { return 122; }
  let a3 = ascii85.ascii85_decode(ascii85.ascii85_encode(&to_bytes("hello")));
  match a3 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("hello")) { return 123; } },
    Err(_) => { return 124; },
  }
  let a4 = ascii85.ascii85_decode(ascii85.ascii85_encode(&to_bytes("AB")));
  match a4 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("AB")) { return 125; } },
    Err(_) => { return 126; },
  }
  let a5 = ascii85.ascii85_decode_with_delim(ascii85.ascii85_encode_with_delim(&to_bytes("AB")));
  match a5 {
    Ok(v) => { if !eq_bytes(&v, &to_bytes("AB")) { return 127; } },
    Err(_) => { return 128; },
  }
  let a6 = ascii85.ascii85_decode_with_delim("AB");
  if a6.is_ok { return 129; }
  if ascii85.ascii85_encode_str("hello") != ascii85.ascii85_encode(&to_bytes("hello")) { return 130; }
  let a7 = ascii85.ascii85_decode_str(ascii85.ascii85_encode_str(mk2(0xC3, 0xA9)));
  match a7 {
    Ok(v) => { if v != mk2(0xC3, 0xA9) { return 131; } },
    Err(_) => { return 132; },
  }

  return 0;
}
