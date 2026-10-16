// p_wave166_convert.xi -- wave 166 lock, part 2/3 (convert reach of the
// string/encoding wishlist): strict Option-shaped str_to_int (row 28),
// strict offset-carrying int parsing (row 45), byte-span windows over
// Vec[UInt8] (row 44 vec half).
// Rows (0 = all hold):
//  1 -- parse_int_opt: plain/signed values incl. "0", "+7", "-0"
//  2 -- parse_int_opt strictness: INT_MAX/INT_MIN parse; junk and overflow
//       on both signs -> None
//  3 -- parse_int_at offsets: "abc123def" -> 123 @ next=6; signs
//  4 -- parse_int_at failure set (bare sign, junk at start, out-of-range
//       start, overflow) + cursor chaining "n=123;m=45"
//  5 -- ByteSpan new/checked/len/is_empty/slice
//  6 -- bytes_span_get/to_vec/eq(cross-vector)/starts_with
//  7 -- bytes_span_find_byte (masked target) + copy_into append
//  8 -- bytes_span_to_str: Ok copy, NUL rejection, OOB rejection, empty Ok
// Setup failures use 20+.

module p_wave166_convert

use xiom.convert.parse;
use xiom.convert.bytes;

fn main() -> Int {
  // Row 1: parse_int_opt basics.
  let p1 = parse.parse_int_opt("0");
  match p1 {
    Some(v) => {
      if v != 0 { return 1; };
    },
    None => { return 1; },
  };
  let p1b = parse.parse_int_opt("42");
  match p1b {
    Some(v) => {
      if v != 42 { return 1; };
    },
    None => { return 1; },
  };
  let p1c = parse.parse_int_opt("-42");
  match p1c {
    Some(v) => {
      if v != -42 { return 1; };
    },
    None => { return 1; },
  };
  let p1d = parse.parse_int_opt("+7");
  match p1d {
    Some(v) => {
      if v != 7 { return 1; };
    },
    None => { return 1; },
  };
  let p1e = parse.parse_int_opt("-0");
  match p1e {
    Some(v) => {
      if v != 0 { return 1; };
    },
    None => { return 1; },
  };

  // Row 2: strictness.
  let p2a = parse.parse_int_opt("9223372036854775807");
  match p2a {
    Some(v) => {
      if v != 9223372036854775807 { return 2; };
    },
    None => { return 2; },
  };
  let p2b = parse.parse_int_opt("-9223372036854775808");
  match p2b {
    Some(v) => {
      if v != (0 - 9223372036854775807 - 1) { return 2; };
    },
    None => { return 2; },
  };
  if parse.parse_int_opt("9223372036854775808").is_some { return 2; };
  if parse.parse_int_opt("-9223372036854775809").is_some { return 2; };
  if parse.parse_int_opt("").is_some { return 2; };
  if parse.parse_int_opt("-").is_some { return 2; };
  if parse.parse_int_opt("+").is_some { return 2; };
  if parse.parse_int_opt("12x").is_some { return 2; };
  if parse.parse_int_opt("x12").is_some { return 2; };
  if parse.parse_int_opt(" 12").is_some { return 2; };
  if parse.parse_int_opt("12 ").is_some { return 2; };
  if parse.parse_int_opt("1 2").is_some { return 2; };
  if parse.parse_int_opt("1.5").is_some { return 2; };
  if parse.parse_int_opt("--1").is_some { return 2; };
  if parse.parse_int_opt("+-1").is_some { return 2; };

  // Row 3: parse_int_at offsets.
  let q3 = parse.parse_int_at("abc123def", 3);
  match q3 {
    Some(pi) => {
      if pi.value != 123 { return 3; };
      if pi.next != 6 { return 3; };
    },
    None => { return 3; },
  };
  let q3b = parse.parse_int_at("123", 0);
  match q3b {
    Some(pi) => {
      if pi.value != 123 { return 3; };
      if pi.next != 3 { return 3; };
    },
    None => { return 3; },
  };
  let q3c = parse.parse_int_at("-7x", 0);
  match q3c {
    Some(pi) => {
      if pi.value != -7 { return 3; };
      if pi.next != 2 { return 3; };
    },
    None => { return 3; },
  };
  let q3d = parse.parse_int_at("+45;", 0);
  match q3d {
    Some(pi) => {
      if pi.value != 45 { return 3; };
      if pi.next != 3 { return 3; };
    },
    None => { return 3; },
  };
  let q3e = parse.parse_int_at("0end", 0);
  match q3e {
    Some(pi) => {
      if pi.value != 0 { return 3; };
      if pi.next != 1 { return 3; };
    },
    None => { return 3; },
  };

  // Row 4: failure set + cursor chaining.
  if parse.parse_int_at("-", 0).is_some { return 4; };
  if parse.parse_int_at("-x", 0).is_some { return 4; };
  if parse.parse_int_at("+", 0).is_some { return 4; };
  if parse.parse_int_at("12x", 3).is_some { return 4; };
  if parse.parse_int_at("x12", 0).is_some { return 4; };
  if parse.parse_int_at("x12", -1).is_some { return 4; };
  if parse.parse_int_at("12", 2).is_some { return 4; };
  if parse.parse_int_at("99999999999999999999", 0).is_some { return 4; };
  if parse.parse_int_at("a99999999999999999999b", 1).is_some { return 4; };
  let q4 = parse.parse_int_at("=123,45", 1);
  match q4 {
    Some(pi) => {
      let q4b = parse.parse_int_at("=123,45", pi.next + 1);
      match q4b {
        Some(pi2) => {
          if pi2.value != 45 { return 4; };
          if pi2.next != 7 { return 4; };
        },
        None => { return 4; },
      };
    },
    None => { return 4; },
  };

  // Row 5: ByteSpan windows.
  let nw5 = bytes.bytes_span_new(-1, -2);
  if bytes.bytes_span_len(&nw5) != 0 { return 5; };
  if !bytes.bytes_span_is_empty(&nw5) { return 5; };
  if nw5.start != 0 { return 5; };
  let nw5b = bytes.bytes_span_new(2, 3);
  if nw5b.start != 2 { return 5; };
  if bytes.bytes_span_len(&nw5b) != 3 { return 5; };
  let ck5 = bytes.bytes_span_checked(6, 1, 3);
  match ck5 {
    Some(sp) => {
      if sp.start != 1 { return 5; };
      if sp.len != 3 { return 5; };
    },
    None => { return 5; },
  };
  if bytes.bytes_span_checked(6, 1, 6).is_some { return 5; };
  if bytes.bytes_span_checked(6, 7, 0).is_some { return 5; };
  if bytes.bytes_span_checked(6, -1, 2).is_some { return 5; };
  if bytes.bytes_span_checked(6, 1, -1).is_some { return 5; };
  let base5 = bytes.bytes_span_new(2, 3);
  let sl5 = bytes.bytes_span_slice(&base5, 1, 1);
  if sl5.start != 3 { return 5; };
  if sl5.len != 1 { return 5; };
  let sl5b = bytes.bytes_span_slice(&base5, 2, 99);
  if sl5b.start != 4 { return 5; };
  if sl5b.len != 1 { return 5; };
  let sl5c = bytes.bytes_span_slice(&base5, -1, -1);
  if sl5c.start != 2 { return 5; };
  if sl5c.len != 0 { return 5; };

  // Row 6: get / to_vec / eq / starts_with.
  var d6: Vec[UInt8] = Vec[UInt8].new();
  d6.push(65);
  d6.push(66);
  d6.push(67);
  d6.push(68);
  d6.push(69);
  d6.push(70);
  let bcd6 = bytes.bytes_span_new(1, 3);
  if bytes.bytes_span_get(&d6, &bcd6, 0) != 66 { return 6; };
  if bytes.bytes_span_get(&d6, &bcd6, 2) != 68 { return 6; };
  if bytes.bytes_span_get(&d6, &bcd6, -1) != 0 { return 6; };
  if bytes.bytes_span_get(&d6, &bcd6, 3) != 0 { return 6; };
  let v6 = bytes.bytes_span_to_vec(&d6, &bcd6);
  if v6.len() != 3 { return 6; };
  if v6[0] != 66 || v6[1] != 67 || v6[2] != 68 { return 6; };
  var d6b: Vec[UInt8] = Vec[UInt8].new();
  d6b.push(88);
  d6b.push(66);
  d6b.push(67);
  d6b.push(68);
  let bcd6b = bytes.bytes_span_new(1, 3);
  if !bytes.bytes_span_eq(&d6, &bcd6, &d6b, &bcd6b) { return 6; };
  let abc6 = bytes.bytes_span_new(0, 3);
  if bytes.bytes_span_eq(&d6, &abc6, &d6, &bcd6) { return 6; };
  let shorter6 = bytes.bytes_span_new(1, 2);
  if bytes.bytes_span_eq(&d6, &bcd6, &d6, &shorter6) { return 6; };
  var pref6: Vec[UInt8] = Vec[UInt8].new();
  pref6.push(66);
  pref6.push(67);
  if !bytes.bytes_span_starts_with(&d6, &bcd6, &pref6) { return 6; };
  var pref6b: Vec[UInt8] = Vec[UInt8].new();
  pref6b.push(66);
  pref6b.push(68);
  if bytes.bytes_span_starts_with(&d6, &bcd6, &pref6b) { return 6; };
  var pref6c: Vec[UInt8] = Vec[UInt8].new();
  pref6c.push(66);
  pref6c.push(67);
  pref6c.push(68);
  pref6c.push(69);
  if bytes.bytes_span_starts_with(&d6, &bcd6, &pref6c) { return 6; };
  var pref6d: Vec[UInt8] = Vec[UInt8].new();
  if !bytes.bytes_span_starts_with(&d6, &bcd6, &pref6d) { return 6; };

  // Row 7: find_byte + copy_into.
  let f7 = bytes.bytes_span_find_byte(&d6, &bcd6, 67);
  match f7 {
    Some(i) => {
      if i != 1 { return 7; };
    },
    None => { return 7; },
  };
  let f7b = bytes.bytes_span_find_byte(&d6, &bcd6, 65);
  if f7b.is_some { return 7; };
  let f7c = bytes.bytes_span_find_byte(&d6, &bcd6, 323);
  match f7c {
    Some(i) => {
      if i != 1 { return 7; };
    },
    None => { return 7; },
  };
  var out7: Vec[UInt8] = Vec[UInt8].new();
  out7.push(1);
  bytes.bytes_span_copy_into(&d6, &bcd6, &mut out7);
  if out7.len() != 4 { return 7; };
  if out7[0] != 1 || out7[1] != 66 || out7[2] != 67 || out7[3] != 68 { return 7; };

  // Row 8: to_str policy.
  let t8 = bytes.bytes_span_to_str(&d6, &bcd6);
  match t8 {
    Ok(s) => {
      if s != "BCD" { return 8; };
    },
    Err(_) => { return 8; },
  };
  var d8: Vec[UInt8] = Vec[UInt8].new();
  d8.push(65);
  d8.push(0);
  d8.push(66);
  let nul8 = bytes.bytes_span_new(0, 3);
  let t8b = bytes.bytes_span_to_str(&d8, &nul8);
  if t8b.is_ok { return 8; };
  let one8 = bytes.bytes_span_new(0, 1);
  let t8c = bytes.bytes_span_to_str(&d8, &one8);
  match t8c {
    Ok(s) => {
      if s != "A" { return 8; };
    },
    Err(_) => { return 8; },
  };
  let oob8 = bytes.bytes_span_new(5, 2);
  let t8d = bytes.bytes_span_to_str(&d8, &oob8);
  if t8d.is_ok { return 8; };
  let emp8 = bytes.bytes_span_new(0, 0);
  let t8e = bytes.bytes_span_to_str(&d8, &emp8);
  match t8e {
    Ok(s) => {
      if s.len() != 0 { return 8; };
    },
    Err(_) => { return 8; },
  };

  return 0;
}
