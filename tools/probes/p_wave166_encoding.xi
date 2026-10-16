// p_wave166_encoding.xi -- wave 166 lock, part 3/3 (encoding reach of the
// string/encoding wishlist): bounded LE/BE unsigned codecs (row 32),
// canonical unpadded lowercase base32 + path percent-encoder (row 46).
// Rows (0 = all hold):
//  1 -- write_u16/u24/u32/u64_le KATs (append order)
//  2 -- write_u64_le INT64_MAX byte pattern
//  3 -- LE writer range errors (negative + above-width)
//  4 -- BE writer KATs + range errors
//  5 -- read_u16/u24/u32/u64_le KATs + offset reads
//  6 -- LE reader bounds errors + end-boundary reads
//  7 -- BE reader KATs + bounds errors
//  8 -- LE/BE round trips + endianness distinctness
//  9 -- base32_encode_lower_nopad RFC 4648-consistent KATs + padded unchanged
// 10 -- base32_decode lowercase/mixed/padded round trips + invalid input
// 11 -- percent_encode_path (slash kept, uppercase hex) + component regression
// 12 -- percent_encode_keep generic + www-form regression
// Setup failures use 20+.

module p_wave166_encoding

use xiom.encoding.le;
use xiom.encoding.base32;
use xiom.encoding.percent;

fn _rb3(x: Int, y: Int, z: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(x as UInt8);
  v.push(y as UInt8);
  v.push(z as UInt8);
  Str::from_utf8(v)
}

fn _bytes6(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) -> Vec[UInt8] {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  v.push(c as UInt8);
  v.push(d as UInt8);
  v.push(e as UInt8);
  v.push(f as UInt8);
  v
}

fn main() -> Int {
  // Row 1: LE writer KATs.
  var v1: Vec[UInt8] = Vec[UInt8].new();
  let w1 = le.write_u16_le(&mut v1, 0x0201);
  if w1.is_err { return 1; };
  if v1.len() != 2 { return 1; };
  if v1[0] != 1 || v1[1] != 2 { return 1; };
  let w1b = le.write_u24_le(&mut v1, 0x030201);
  if w1b.is_err { return 1; };
  if v1.len() != 5 { return 1; };
  if v1[2] != 1 || v1[3] != 2 || v1[4] != 3 { return 1; };
  var v1c: Vec[UInt8] = Vec[UInt8].new();
  let w1c = le.write_u32_le(&mut v1c, 0x04030201);
  if w1c.is_err { return 1; };
  if v1c.len() != 4 { return 1; };
  if v1c[0] != 1 || v1c[1] != 2 || v1c[2] != 3 || v1c[3] != 4 { return 1; };
  var v1d: Vec[UInt8] = Vec[UInt8].new();
  let w1d = le.write_u64_le(&mut v1d, 0x0102030405060708);
  if w1d.is_err { return 1; };
  if v1d.len() != 8 { return 1; };
  if v1d[0] != 8 || v1d[1] != 7 || v1d[2] != 6 || v1d[3] != 5 { return 1; };
  if v1d[4] != 4 || v1d[5] != 3 || v1d[6] != 2 || v1d[7] != 1 { return 1; };

  // Row 2: u64 at INT64_MAX.
  var v2: Vec[UInt8] = Vec[UInt8].new();
  let w2 = le.write_u64_le(&mut v2, 9223372036854775807);
  if w2.is_err { return 2; };
  if v2.len() != 8 { return 2; };
  if v2[0] != 255 || v2[1] != 255 || v2[2] != 255 || v2[3] != 255 { return 2; };
  if v2[4] != 255 || v2[5] != 255 || v2[6] != 255 || v2[7] != 127 { return 2; };

  // Row 3: LE range errors.
  var v3: Vec[UInt8] = Vec[UInt8].new();
  if le.write_u16_le(&mut v3, -1).is_ok { return 3; };
  if le.write_u16_le(&mut v3, 0x10000).is_ok { return 3; };
  if le.write_u24_le(&mut v3, 0x1000000).is_ok { return 3; };
  if le.write_u32_le(&mut v3, -5).is_ok { return 3; };
  if le.write_u32_le(&mut v3, 0x100000000).is_ok { return 3; };
  if le.write_u64_le(&mut v3, -1).is_ok { return 3; };
  if v3.len() != 0 { return 3; };
  if le.write_u16_le(&mut v3, 0xFFFF).is_err { return 3; };
  if le.write_u24_le(&mut v3, 0xFFFFFF).is_err { return 3; };
  if le.write_u32_le(&mut v3, 0xFFFFFFFF).is_err { return 3; };

  // Row 4: BE writer KATs.
  var v4: Vec[UInt8] = Vec[UInt8].new();
  let w4 = le.write_u16_be(&mut v4, 0x0201);
  if w4.is_err { return 4; };
  if v4[0] != 2 || v4[1] != 1 { return 4; };
  var v4b: Vec[UInt8] = Vec<UInt8>.new();
  let w4b = le.write_u24_be(&mut v4b, 0x030201);
  if w4b.is_err { return 4; };
  if v4b[0] != 3 || v4b[1] != 2 || v4b[2] != 1 { return 4; };
  var v4c: Vec[UInt8] = Vec[UInt8].new();
  let w4c = le.write_u32_be(&mut v4c, 0x04030201);
  if w4c.is_err { return 4; };
  if v4c[0] != 4 || v4c[1] != 3 || v4c[2] != 2 || v4c[3] != 1 { return 4; };
  var v4d: Vec<UInt8> = Vec[UInt8].new();
  let w4d = le.write_u64_be(&mut v4d, 0x0102030405060708);
  if w4d.is_err { return 4; };
  if v4d[0] != 1 || v4d[1] != 2 || v4d[2] != 3 || v4d[3] != 4 { return 4; };
  if v4d[4] != 5 || v4d[5] != 6 || v4d[6] != 7 || v4d[7] != 8 { return 4; };
  var v4e: Vec<UInt8> = Vec<UInt8>.new();
  if le.write_u24_be(&mut v4e, 0x1000000).is_ok { return 4; };
  if le.write_u64_be(&mut v4e, -1).is_ok { return 4; };
  if le.write_u16_be(&mut v4e, 0x10000).is_ok { return 4; };

  // Row 5: LE reader KATs.
  var d5: Vec[UInt8] = Vec[UInt8].new();
  d5.push(1);
  d5.push(2);
  let r5 = le.read_u16_le(&d5, 0);
  match r5 {
    Ok(x) => {
      if x != 513 { return 5; };
    },
    Err(_) => { return 5; },
  };
  var d5b: Vec<UInt8> = Vec[UInt8].new();
  d5b.push(1);
  d5b.push(2);
  d5b.push(3);
  let r5b = le.read_u24_le(&d5b, 0);
  match r5b {
    Ok(x) => {
      if x != 197121 { return 5; };
    },
    Err(_) => { return 5; },
  };
  var d5c: Vec<UInt8> = Vec[UInt8].new();
  d5c.push(255);
  d5c.push(1);
  d5c.push(2);
  d5c.push(3);
  d5c.push(4);
  let r5c = le.read_u32_le(&d5c, 1);
  match r5c {
    Ok(x) => {
      if x != 67305985 { return 5; };
    },
    Err(_) => { return 5; },
  };
  var d5d: Vec[UInt8] = Vec[UInt8].new();
  d5d.push(8);
  d5d.push(7);
  d5d.push(6);
  d5d.push(5);
  d5d.push(4);
  d5d.push(3);
  d5d.push(2);
  d5d.push(1);
  let r5d = le.read_u64_le(&d5d, 0);
  match r5d {
    Ok(x) => {
      if x != 72623859790382856 { return 5; };
    },
    Err(_) => { return 5; },
  };
  let r5e = le.read_u64_le(&v2, 0);
  match r5e {
    Ok(x) => {
      if x != 9223372036854775807 { return 5; };
    },
    Err(_) => { return 5; },
  };

  // Row 6: LE reader bounds.
  if le.read_u16_le(&d5, -1).is_ok { return 6; };
  if le.read_u16_le(&d5, 1).is_ok { return 6; };
  if le.read_u24_le(&d5, 0).is_ok { return 6; };
  if le.read_u32_le(&d5b, 0).is_ok { return 6; };
  var seven6: Vec[UInt8] = Vec<UInt8>.new();
  seven6.push(0);
  seven6.push(0);
  seven6.push(0);
  seven6.push(0);
  seven6.push(0);
  seven6.push(0);
  seven6.push(0);
  if le.read_u64_le(&seven6, 0).is_ok { return 6; };
  var three6: Vec[UInt8] = Vec[UInt8].new();
  three6.push(0);
  three6.push(1);
  three6.push(2);
  let r6 = le.read_u16_le(&three6, 1);
  match r6 {
    Ok(x) => {
      if x != 513 { return 6; };
    },
    Err(_) => { return 6; },
  };

  // Row 7: BE reader KATs + bounds.
  let r7 = le.read_u16_be(&d5, 0);
  match r7 {
    Ok(x) => {
      if x != 258 { return 7; };
    },
    Err(_) => { return 7; },
  };
  var d7: Vec[UInt8] = Vec<UInt8>.new();
  d7.push(3);
  d7.push(2);
  d7.push(1);
  let r7b = le.read_u24_be(&d7, 0);
  match r7b {
    Ok(x) => {
      if x != 197121 { return 7; };
    },
    Err(_) => { return 7; },
  };
  var d7b: Vec<UInt8> = Vec<UInt8>.new();
  d7b.push(9);
  d7b.push(4);
  d7b.push(3);
  d7b.push(2);
  d7b.push(1);
  let r7c = le.read_u32_be(&d7b, 1);
  match r7c {
    Ok(x) => {
      if x != 67305985 { return 7; };
    },
    Err(_) => { return 7; },
  };
  let r7d = le.read_u64_be(&v4d, 0);
  match r7d {
    Ok(x) => {
      if x != 72623859790382856 { return 7; };
    },
    Err(_) => { return 7; },
  };
  if le.read_u16_be(&d5, 1).is_ok { return 7; };
  if le.read_u24_be(&d5, 0).is_ok { return 7; };
  if le.read_u32_be(&d7, 0).is_ok { return 7; };
  if le.read_u64_be(&seven6, 0).is_ok { return 7; };

  // Row 8: round trips + distinctness.
  var rt8: Vec[UInt8] = Vec[UInt8].new();
  let _ = le.write_u16_le(&mut rt8, 0);
  let _ = le.write_u16_le(&mut rt8, 65535);
  let _ = le.write_u16_le(&mut rt8, 513);
  let g8a = le.read_u16_le(&rt8, 0);
  let g8b = le.read_u16_le(&rt8, 2);
  let g8c = le.read_u16_le(&rt8, 4);
  match g8a {
    Ok(x) => {
      if x != 0 { return 8; };
    },
    Err(_) => { return 8; },
  };
  match g8b {
    Ok(x) => {
      if x != 65535 { return 8; };
    },
    Err(_) => { return 8; },
  };
  match g8c {
    Ok(x) => {
      if x != 513 { return 8; };
    },
    Err(_) => { return 8; },
  };
  var rt8b: Vec<UInt8> = Vec<UInt8>.new();
  let _ = le.write_u64_be(&mut rt8b, 9223372036854775807);
  let g8d = le.read_u64_be(&rt8b, 0);
  match g8d {
    Ok(x) => {
      if x != 9223372036854775807 { return 8; };
    },
    Err(_) => { return 8; },
  };
  var le8: Vec[UInt8] = Vec[UInt8].new();
  let _ = le.write_u16_le(&mut le8, 0x0201);
  var be8: Vec[UInt8] = Vec<UInt8>.new();
  let _ = le.write_u16_be(&mut be8, 0x0201);
  if le8[0] == be8[0] { return 8; };
  let g8e = le.read_u16_be(&le8, 0);
  match g8e {
    Ok(x) => {
      if x != 0x0102 { return 8; };
    },
    Err(_) => { return 8; },
  };

  // Row 9: base32 unpadded lowercase KATs (RFC 4648 vectors, lowercased).
  var foobar9 = _bytes6(102, 111, 111, 98, 97, 114);
  let b9 = base32.base32_encode_lower_nopad(&foobar9);
  if b9 != "mzxw6ytboi" { return 9; };
  var empty9: Vec[UInt8] = Vec[UInt8].new();
  let b9b = base32.base32_encode_lower_nopad(&empty9);
  if b9b.len() != 0 { return 9; };
  var f9: Vec<UInt8> = Vec[UInt8].new();
  f9.push(102);
  if base32.base32_encode_lower_nopad(&f9) != "my" { return 9; };
  var fo9: Vec[UInt8] = Vec<UInt8>.new();
  fo9.push(102);
  fo9.push(111);
  if base32.base32_encode_lower_nopad(&fo9) != "mzxq" { return 9; };
  var foo9: Vec[UInt8] = Vec<UInt8>.new();
  foo9.push(102);
  foo9.push(111);
  foo9.push(111);
  if base32.base32_encode_lower_nopad(&foo9) != "mzxw6" { return 9; };
  var foob9: Vec<UInt8> = Vec<UInt8>.new();
  foob9.push(102);
  foob9.push(111);
  foob9.push(111);
  foob9.push(98);
  if base32.base32_encode_lower_nopad(&foob9) != "mzxw6yq" { return 9; };
  var fooba9: Vec<UInt8> = Vec<UInt8>.new();
  fooba9.push(102);
  fooba9.push(111);
  fooba9.push(111);
  fooba9.push(98);
  fooba9.push(97);
  if base32.base32_encode_lower_nopad(&fooba9) != "mzxw6ytb" { return 9; };
  if base32.base32_encode(&foobar9) != "MZXW6YTBOI======" { return 9; };

  // Row 10: base32 decode lowercase/mixed/padded + invalids.
  let d10 = base32.base32_decode("mzxw6ytboi");
  match d10 {
    Ok(bytes10) => {
      if bytes10.len() != 6 { return 10; };
      if bytes10[0] != 102 || bytes10[5] != 114 { return 10; };
    },
    Err(_) => { return 10; },
  };
  let d10b = base32.base32_decode(base32.base32_encode_lower_nopad(&foobar9));
  match d10b {
    Ok(bytes10b) => {
      if bytes10b.len() != 6 { return 10; };
      if bytes10b[2] != 111 { return 10; };
    },
    Err(_) => { return 10; },
  };
  let d10c = base32.base32_decode("MZXW6ytbOI");
  match d10c {
    Ok(bytes10c) => {
      if bytes10c.len() != 6 { return 10; };
      if bytes10c[3] != 98 { return 10; };
    },
    Err(_) => { return 10; },
  };
  let d10d = base32.base32_decode("MZXW6YTBOI======");
  match d10d {
    Ok(bytes10d) => {
      if bytes10d.len() != 6 { return 10; };
    },
    Err(_) => { return 10; },
  };
  let d10e = base32.base32_decode("mzxw6ytb1");
  if d10e.is_ok { return 10; };
  let d10f = base32.base32_decode("mzxw6ytbo");
  if d10f.is_ok { return 10; };

  // Row 11: percent_encode_path.
  if percent.percent_encode_path("/a b/c") != "/a%20b/c" { return 11; };
  if percent.percent_encode_path("?x=1") != "%3Fx%3D1" { return 11; };
  let s11 = _rb3(97, 0xC3, 0xA9) + "b/x";
  if percent.percent_encode_path(s11) != "a%C3%A9b/x" { return 11; };
  if percent.percent_encode_component("/a b") != "%2Fa%20b" { return 11; };
  if percent.percent_encode("/a") != "%2Fa" { return 11; };

  // Row 12: percent_encode_keep + form regression.
  if percent.percent_encode_keep("/a;b", ";") != "%2Fa;b" { return 12; };
  if percent.percent_encode_keep("/a", "") != "%2Fa" { return 12; };
  if percent.percent_encode_keep("k=v", "=") != "k=v" { return 12; };
  if percent.percent_encode_www_form("a b") != "a+b" { return 12; };
  if percent.percent_encode("a b") != "a%20b" { return 12; };

  return 0;
}
