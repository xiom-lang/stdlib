// p_wave173_shapes.xi -- wave 173 lock: the mechanical `ensures: true`
// clauses in the wave-166/168/170 coverage fill are now real functional
// guards. This probe exercises the success AND error paths so the runtime
// contract checks see each tightened clause.
// Rows: 1 LE/BE writer ranges + lengths, 2 LE/BE reader bounds, 3 ASCII
// boundaries + low-byte masking, 4 ASCII case mapping, 5 code-point
// validity/byte lengths, 6 encode/build/offsets/cursor, 7 split-once/
// words/before/after, 8 delimiter scans + spans, 9 byte spans, 10 path
// glob dialects, 11 assertion report/JSON lengths, 12 zip writer new/
// add/finish.
// Returns 0 when all rows hold; a nonzero return names the first failing row.
//
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_wave173_shapes

use xiom.encoding.le;
use xiom.string.ascii;
use xiom.string.codepoint;
use xiom.string.split;
use xiom.convert.bytes;
use xiom.misc.glob;
use xiom.test.assertions;
use xiom.compress.zip;

fn main() -> Int {
  // --- row 1: LE/BE writer ranges and length growth ---
  var out = Vec[UInt8].new();
  let w0 = le.write_u16_le(&mut out, 0x1234);
  if !w0.is_ok || out.len() != 2 { return 1; }
  let mark0 = out.len();
  let w1 = le.write_u16_le(&mut out, 0x10000);
  if !w1.is_err || out.len() != mark0 { return 1; }
  let w2 = le.write_u24_le(&mut out, 0x123456);
  if !w2.is_ok || out.len() != mark0 + 3 { return 1; }
  let w3 = le.write_u24_le(&mut out, 0x1000000);
  if !w3.is_err || out.len() != mark0 + 3 { return 1; }
  let w4 = le.write_u32_le(&mut out, 0x89ABCDEF);
  if !w4.is_ok || out.len() != mark0 + 7 { return 1; }
  let w5 = le.write_u32_le(&mut out, 0x100000000);
  if !w5.is_err || out.len() != mark0 + 7 { return 1; }
  let w6 = le.write_u16_be(&mut out, 0x1234);
  if !w6.is_ok || out.len() != mark0 + 9 { return 1; }
  let w7 = le.write_u24_be(&mut out, 0x123456);
  if !w7.is_ok || out.len() != mark0 + 12 { return 1; }
  let w8 = le.write_u64_be(&mut out, 0x0102030405060708);
  if !w8.is_ok || out.len() != mark0 + 20 { return 1; }
  let w9 = le.write_u64_be(&mut out, 0 - 1);
  if !w9.is_err || out.len() != mark0 + 20 { return 1; }

  // --- row 2: LE/BE reader bounds and values ---
  var buf = Vec[UInt8].new();
  buf.push(0x01); buf.push(0x02); buf.push(0x03); buf.push(0x04);
  buf.push(0x05); buf.push(0x06); buf.push(0x07); buf.push(0x08);
  match le.read_u16_le(&buf, 0) {
    Ok(v) => { if v != 0x0201 { return 2; } },
    Err(_) => { return 2; },
  };
  match le.read_u24_le(&buf, 0) {
    Ok(v) => { if v != 0x030201 { return 2; } },
    Err(_) => { return 2; },
  };
  match le.read_u32_le(&buf, 0) {
    Ok(v) => { if v != 0x04030201 { return 2; } },
    Err(_) => { return 2; },
  };
  match le.read_u64_le(&buf, 0) {
    Ok(v) => { if v != 0x0807060504030201 { return 2; } },
    Err(_) => { return 2; },
  };
  match le.read_u16_be(&buf, 0) {
    Ok(v) => { if v != 0x0102 { return 2; } },
    Err(_) => { return 2; },
  };
  match le.read_u24_be(&buf, 0) {
    Ok(v) => { if v != 0x010203 { return 2; } },
    Err(_) => { return 2; },
  };
  match le.read_u32_be(&buf, 0) {
    Ok(v) => { if v != 0x01020304 { return 2; } },
    Err(_) => { return 2; },
  };
  match le.read_u64_be(&buf, 0) {
    Ok(v) => { if v != 0x0102030405060708 { return 2; } },
    Err(_) => { return 2; },
  };
  match le.read_u16_le(&buf, 7) {
    Ok(_) => { return 2; },
    Err(_) => {},
  };
  match le.read_u24_be(&buf, 6) {
    Ok(_) => { return 2; },
    Err(_) => {},
  };
  match le.read_u64_le(&buf, 1) {
    Ok(_) => { return 2; },
    Err(_) => {},
  };
  match le.read_u16_be(&buf, 0 - 1) {
    Ok(_) => { return 2; },
    Err(_) => {},
  };

  // --- row 3: ASCII boundaries + low-byte masking ---
  if !ascii.ascii_is_digit(48) || ascii.ascii_is_digit(47) || ascii.ascii_is_digit(58) { return 3; }
  if !ascii.ascii_is_digit(0x130) { return 3; }
  if !ascii.ascii_is_upper(65) || ascii.ascii_is_upper(64) || ascii.ascii_is_upper(91) { return 3; }
  if !ascii.ascii_is_lower(97) || ascii.ascii_is_lower(96) || ascii.ascii_is_lower(123) { return 3; }
  if !ascii.ascii_is_alpha(65) || !ascii.ascii_is_alpha(122) || ascii.ascii_is_alpha(91) { return 3; }
  if !ascii.ascii_is_alnum(48) || !ascii.ascii_is_alnum(90) || ascii.ascii_is_alnum(45) { return 3; }
  if !ascii.ascii_is_space(32) || !ascii.ascii_is_space(13) || ascii.ascii_is_space(14) { return 3; }
  if !ascii.ascii_is_blank(9) || ascii.ascii_is_blank(10) { return 3; }
  if !ascii.ascii_is_hex(48) || !ascii.ascii_is_hex(70) || !ascii.ascii_is_hex(102) { return 3; }
  if ascii.ascii_is_hex(71) { return 3; }
  if !ascii.ascii_is_control(31) || !ascii.ascii_is_control(127) || ascii.ascii_is_control(32) { return 3; }
  if !ascii.ascii_is_printable(32) || !ascii.ascii_is_printable(126) || ascii.ascii_is_printable(127) { return 3; }
  if !ascii.ascii_in_set(59, ";,") || ascii.ascii_in_set(46, ";,") || ascii.ascii_in_set(0, "") { return 3; }

  // --- row 4: ASCII case mapping (low-byte domain) ---
  if ascii.ascii_upper_byte(97) != 65 || ascii.ascii_upper_byte(122) != 90 { return 4; }
  if ascii.ascii_upper_byte(65) != 65 || ascii.ascii_upper_byte(255) != 255 { return 4; }
  if ascii.ascii_upper_byte(0 - 1) != 255 { return 4; }
  if ascii.ascii_lower_byte(65) != 97 || ascii.ascii_lower_byte(90) != 122 { return 4; }
  if ascii.ascii_lower_byte(97) != 97 || ascii.ascii_lower_byte(321) != 97 { return 4; }

  // --- row 5: code-point validity and byte lengths ---
  if !codepoint.codepoint_valid(0) || !codepoint.codepoint_valid(0x10FFFF) { return 5; }
  if codepoint.codepoint_valid(0 - 1) || codepoint.codepoint_valid(0x110000) { return 5; }
  if codepoint.codepoint_valid(0xD800) || codepoint.codepoint_valid(0xDFFF) { return 5; }
  if codepoint.codepoint_byte_len(0) != 1 || codepoint.codepoint_byte_len(0x7F) != 1 { return 5; }
  if codepoint.codepoint_byte_len(0x80) != 2 || codepoint.codepoint_byte_len(0x7FF) != 2 { return 5; }
  if codepoint.codepoint_byte_len(0x800) != 3 || codepoint.codepoint_byte_len(0xFFFF) != 3 { return 5; }
  if codepoint.codepoint_byte_len(0x10000) != 4 || codepoint.codepoint_byte_len(0x10FFFF) != 4 { return 5; }
  if codepoint.codepoint_byte_len(0 - 1) != 0 || codepoint.codepoint_byte_len(0xD800) != 0 { return 5; }

  // --- row 6: encode/build/offsets/cursor ---
  var enc = Vec[UInt8].new();
  let e0 = codepoint.codepoint_encode(65, &mut enc);
  if !e0.is_ok || enc.len() != 1 { return 6; }
  let e1 = codepoint.codepoint_encode(0x20AC, &mut enc);
  if !e1.is_ok || enc.len() != 4 { return 6; }
  let e2 = codepoint.codepoint_encode(0xD800, &mut enc);
  if !e2.is_err || enc.len() != 4 { return 6; }

  var cps = Vec[Int].new();
  cps.push(65); cps.push(0x20AC);
  let built = codepoint.str_from_codepoints(&cps);
  match built {
    Ok(s) => { if s.len() != 4 { return 6; } },
    Err(_) => { return 6; },
  };
  var empty_cps = Vec[Int].new();
  let built0 = codepoint.str_from_codepoints(&empty_cps);
  if !built0.is_ok { return 6; }
  var nul_cps = Vec[Int].new();
  nul_cps.push(0);
  let built1 = codepoint.str_from_codepoints(&nul_cps);
  if !built1.is_err { return 6; }
  var sur_cps = Vec[Int].new();
  sur_cps.push(0xD800);
  let built2 = codepoint.str_from_codepoints(&sur_cps);
  if !built2.is_err { return 6; }

  let offs = codepoint.codepoint_offsets("A\u{20AC}");
  if offs.len() != 2 || offs[0] != 0 || offs[1] != 1 { return 6; }
  if !codepoint.codepoints_valid("A\u{20AC}") { return 6; }
  let empty_offs = codepoint.codepoint_offsets("");
  if empty_offs.len() != 0 { return 6; }

  var cur = codepoint.codepoint_cursor("A\u{20AC}");
  match codepoint.codepoint_next(&mut cur) {
    Some(c) => { if c.value != 65 || c.byte_len != 1 || c.start != 0 { return 6; } },
    None => { return 6; },
  };
  match codepoint.codepoint_next(&mut cur) {
    Some(c) => { if c.value != 0x20AC || c.byte_len != 3 || c.start != 1 { return 6; } },
    None => { return 6; },
  };
  match codepoint.codepoint_next(&mut cur) {
    Some(_) => { return 6; },
    None => {},
  };
  if cur.pos != 4 { return 6; }

  // --- row 7: split-once / words / before / after ---
  let (p0, p1) = split.str_split_once("a=b", "=");
  if p0 != "a" || p1 != "b" { return 7; }
  let (q0, q1) = split.str_split_once("abc", "=");
  if q0 != "abc" || q1 != "" { return 7; }
  let (r0, r1) = split.str_split_once("abc", "");
  if r0 != "" || r1 != "abc" { return 7; }
  let words0 = split.str_words("");
  if words0.len() != 0 { return 7; }
  let words1 = split.str_words(" a  b ");
  if words1.len() != 2 { return 7; }
  if split.str_before("a=b", "=") != "a" || split.str_after("a=b", "=") != "b" { return 7; }
  if split.str_before("abc", "=") != "abc" || split.str_after("abc", "=") != "" { return 7; }
  if split.str_before("abc", "") != "" || split.str_after("abc", "") != "abc" { return 7; }

  // --- row 8: delimiter scans and flat spans ---
  var ds = Vec[Str].new();
  ds.push("="); ds.push("==");
  let f0 = split.str_find_any_at("a==b", &ds, 0);
  match f0 {
    Some(i) => { if i != 1 { return 8; } },
    None => { return 8; },
  };
  let f1 = split.str_find_any_at("abc", &ds, 0);
  if f1.is_some { return 8; }
  let f2 = split.str_find_any_at("a=b", &ds, 9);
  if f2.is_some { return 8; }
  var none_ds = Vec[Str].new();
  let f3 = split.str_find_any_at("a=b", &none_ds, 0);
  if f3.is_some { return 8; }
  if split.str_delim_len_at("a==b", &ds, 1) != 2 { return 8; }
  if split.str_delim_len_at("a==b", &ds, 0) != 0 { return 8; }
  if split.str_delim_len_at("a==b", &ds, 0 - 1) != 0 { return 8; }
  if split.str_delim_len_at("a==b", &ds, 99) != 0 { return 8; }
  let sp0 = split.str_split_spans("a,b", ",");
  if sp0.len() != 4 || sp0[0] != 0 || sp0[1] != 1 || sp0[2] != 2 || sp0[3] != 3 { return 8; }
  let sp1 = split.str_split_spans("", ",");
  if sp1.len() != 2 || sp1[0] != 0 || sp1[1] != 0 { return 8; }
  let sp2 = split.str_split_any_spans("a==b", &ds);
  if sp2.len() != 4 || sp2[0] != 0 || sp2[1] != 1 || sp2[2] != 3 || sp2[3] != 4 { return 8; }
  let sp3 = split.str_split_any_spans("xyz", &none_ds);
  if sp3.len() != 2 || sp3[0] != 0 || sp3[1] != 3 { return 8; }

  // --- row 9: byte spans ---
  var data = Vec[UInt8].new();
  data.push(10); data.push(20); data.push(30); data.push(40);
  let checked = bytes.bytes_span_checked(4, 1, 2);
  match checked {
    Some(s) => { if s.start != 1 || s.len != 2 { return 9; } },
    None => { return 9; },
  };
  let bad0 = bytes.bytes_span_checked(4, 3, 2);
  if bad0.is_some { return 9; }
  let bad1 = bytes.bytes_span_checked(4, 0 - 1, 1);
  if bad1.is_some { return 9; }
  let spn = bytes.bytes_span_new(1, 2);
  if bytes.bytes_span_is_empty(&spn) { return 9; }
  let spe = bytes.bytes_span_new(0, 0);
  if !bytes.bytes_span_is_empty(&spe) { return 9; }
  if bytes.bytes_span_get(&data, &spn, 0) != 20 { return 9; }
  if bytes.bytes_span_get(&data, &spn, 9) != 0 { return 9; }
  let far = bytes.bytes_span_new(10, 2);
  if bytes.bytes_span_get(&data, &far, 0) != 0 { return 9; }
  var copied = Vec[UInt8].new();
  bytes.bytes_span_copy_into(&data, &spn, &mut copied);
  if copied.len() != 2 || copied[0] != 20 || copied[1] != 30 { return 9; }
  if !bytes.bytes_span_eq(&data, &spn, &data, &spn) { return 9; }
  let sp_short = bytes.bytes_span_new(2, 1);
  if bytes.bytes_span_eq(&data, &spn, &data, &sp_short) { return 9; }
  var pre = Vec[UInt8].new();
  pre.push(20);
  if !bytes.bytes_span_starts_with(&data, &spn, &pre) { return 9; }
  var longp = Vec[UInt8].new();
  longp.push(20); longp.push(30); longp.push(40);
  if bytes.bytes_span_starts_with(&data, &spn, &longp) { return 9; }
  var empty_p = Vec[UInt8].new();
  if !bytes.bytes_span_starts_with(&data, &spn, &empty_p) { return 9; }
  let found = bytes.bytes_span_find_byte(&data, &spn, 30);
  match found {
    Some(i) => { if i != 1 { return 9; } },
    None => { return 9; },
  };
  let notfound = bytes.bytes_span_find_byte(&data, &spn, 99);
  if notfound.is_some { return 9; }
  let nonefound = bytes.bytes_span_find_byte(&data, &spe, 10);
  if nonefound.is_some { return 9; }
  match bytes.bytes_span_to_str(&data, &spn) {
    Ok(s) => { if s.len() != 2 { return 9; } },
    Err(_) => { return 9; },
  };
  var nul_data = Vec[UInt8].new();
  nul_data.push(65); nul_data.push(0); nul_data.push(66);
  let nul_span = bytes.bytes_span_new(0, 3);
  match bytes.bytes_span_to_str(&nul_data, &nul_span) {
    Ok(_) => { return 9; },
    Err(_) => {},
  };
  match bytes.bytes_span_to_str(&data, &far) {
    Ok(_) => { return 9; },
    Err(_) => {},
  };

  // --- row 10: path glob dialects ---
  if !glob.glob_match_path("", "", '/') { return 10; }
  if glob.glob_match_path("", "x", '/') { return 10; }
  if !glob.glob_match_path("*", "a", '/') { return 10; }
  if glob.glob_match_path("*", "a/b", '/') { return 10; }
  if !glob.glob_match_path("**", "a/b", '/') { return 10; }
  if !glob.glob_match_path("a/**", "a", '/') { return 10; }
  if !glob.glob_match_path("a/*", "a/b", '/') { return 10; }
  if glob.glob_match_path("a/*", "a/b/c", '/') { return 10; }
  if !glob.glob_match_path_any("", "") { return 10; }
  if !glob.glob_match_path_any("**", "a/b") { return 10; }
  if glob.glob_match_path_any("*", "a/b") { return 10; }

  // --- row 11: assertion summary/report/JSON lengths ---
  var acc = assertions.assertions_new();
  let sum0 = assertions.assertions_summary(&acc);
  if sum0.len() < 12 { return 11; }
  let rep0 = assertions.assertions_report(&acc);
  if rep0.len() < sum0.len() { return 11; }
  let js0 = assertions.assertions_to_json(&acc);
  if js0.len() < 30 { return 11; }
  assertions.check_eq_int(&mut acc, 1, 1, "ok");
  assertions.check_eq_int(&mut acc, 1, 2, "bad");
  if assertions.assertions_failed(&acc) != 1 { return 11; }
  let sum1 = assertions.assertions_summary(&acc);
  if sum1.len() < 12 { return 11; }
  let rep1 = assertions.assertions_report(&acc);
  if rep1.len() < sum1.len() { return 11; }
  let js1 = assertions.assertions_to_json(&acc);
  if js1.len() < 30 { return 11; }

  // --- row 12: zip writer new/add/finish ---
  var w = zip.zip_writer_new();
  if w.count != 0 || w.out.len() != 0 || w.central.len() != 0 { return 12; }
  var payload = Vec[UInt8].new();
  payload.push(65); payload.push(66);
  let add0 = zip.zip_writer_add(&mut w, "a.txt", &payload, zip.ZIP_METHOD_STORED);
  if !add0.is_ok || w.count != 1 { return 12; }
  let add1 = zip.zip_writer_add(&mut w, "", &payload, zip.ZIP_METHOD_STORED);
  if !add1.is_err { return 12; }
  let fin = zip.zip_writer_finish(&mut w);
  match fin {
    Ok(stream) => {
      if stream.len() < 22 { return 12; }
      if stream[0] != 0x50 || stream[1] != 0x4B { return 12; }
    },
    Err(_) => { return 12; },
  };

  return 0;
}
