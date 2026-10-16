// p_wave166_shapes.xi -- wave 166 lock, part 1/3 (string reach of the
// string/encoding wishlist): allocation-free line accessors (row 2), ASCII
// byte classifiers (row 35), delimiter before/after + split-into-offsets
// (row 36), borrowed Str views (row 19), span/byte-slice API on Str (row 44),
// UTF-8 code-point helpers (row 30), dependency-free Vec[UInt8] -> Str
// builder path (row 20).
// Rows (0 = all hold):
//  1 -- lines_count: "" -> 1, "a" -> 1, "a\nb" -> 2, "a\nb\n" -> 3
//  2 -- lines_span: "ab\ncde\n" -> (0,2) (3,6) (7,7); out of range -> None;
//       empty source -> (0,0)
//  3 -- lines_newline_index: "a\nb\n" -> [1,3]; "abc" -> empty
//  4 -- LineCursor walk over "x\ny\nz": (0,1) (2,3) (4,5) then None
//  5 -- lines_slice materializes line 1 of "ab\ncde" as "cde"; idx 2 -> None
//  6 -- ascii byte classifiers: digit/upper/lower/alpha/alnum incl. masking
//  7 -- ascii byte classifiers: space/blank/hex/control/printable
//  8 -- ascii_in_set membership + ascii_upper_byte/ascii_lower_byte mapping
//  9 -- str_before/str_after incl. absent delimiter and empty delimiter
// 10 -- str_find_any_at from-offset scan + str_delim_len_at longest match
// 11 -- str_split_spans: "a,b," -> [0,1 2,3 4,4]; empty delim per-byte;
//       empty source single empty span
// 12 -- str_split_any_spans: longest-delimiter-wins + empty delims whole span
// 13 -- StrView basics: view_of len/is_empty/byte_at + out-of-range 0
// 14 -- view_range clamp + view_range_checked strict Some/None
// 15 -- view_slice relative + view_eq + view_starts_with
// 16 -- view_find offset-relative search incl. empty needle
// 17 -- codepoint_at strict decode 1/2/3/4-byte + malformed None set
// 18 -- CodePointCursor walk + codepoint_offsets + codepoints_valid
// 19 -- codepoint_encode byte KATs + Err set; codepoint_byte_len
// 20 -- str_from_codepoints build + NUL/invalid rejection + round trip
// 21 -- sb_into_str dependency-free materializer (incl. NUL truncation)
// Setup failures use 20+.

module p_wave166_shapes

use xiom.string;
use xiom.string.lines;
use xiom.string.ascii;
use xiom.string.split;
use xiom.string.view;
use xiom.string.codepoint;
use xiom.string.builder;

// Checks that a lines span equals (a, b).
fn _span_is(sp: Option[(Int, Int)], a: Int, b: Int) -> Bool {
  match sp {
    Some(pair) => {
      return pair.0 == a && pair.1 == b;
    },
    None => {
      return false;
    },
  }
}

// Raw-byte Str fixtures: source `\xNN` escapes are CODE POINT escapes (they
// re-encode as UTF-8), so exact bytes come through Str::from_utf8 (the
// runtime copy path), which is independent of the decoders under test.
fn _rb1(x: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(x as UInt8);
  Str::from_utf8(v)
}

fn _rb2(x: Int, y: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(x as UInt8);
  v.push(y as UInt8);
  Str::from_utf8(v)
}

fn _rb3(x: Int, y: Int, z: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(x as UInt8);
  v.push(y as UInt8);
  v.push(z as UInt8);
  Str::from_utf8(v)
}

fn _rb4(w: Int, x: Int, y: Int, z: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(w as UInt8);
  v.push(x as UInt8);
  v.push(y as UInt8);
  v.push(z as UInt8);
  Str::from_utf8(v)
}

fn _rb6(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  v.push(c as UInt8);
  v.push(d as UInt8);
  v.push(e as UInt8);
  v.push(f as UInt8);
  Str::from_utf8(v)
}

fn main() -> Int {
  // Row 1: lines_count.
  if lines.lines_count("") != 1 { return 1; };
  if lines.lines_count("a") != 1 { return 1; };
  if lines.lines_count("a\nb") != 2 { return 1; };
  if lines.lines_count("a\nb\n") != 3 { return 1; };

  // Row 2: lines_span.
  let s2 = "ab\ncde\n";
  if !_span_is(lines.lines_span(s2, 0), 0, 2) { return 2; };
  if !_span_is(lines.lines_span(s2, 1), 3, 6) { return 2; };
  if !_span_is(lines.lines_span(s2, 2), 7, 7) { return 2; };
  let out2 = lines.lines_span(s2, 3);
  if out2.is_some { return 2; };
  let neg2 = lines.lines_span(s2, -1);
  if neg2.is_some { return 2; };
  if !_span_is(lines.lines_span("", 0), 0, 0) { return 2; };

  // Row 3: newline index.
  let nl3 = lines.lines_newline_index("a\nb\n");
  if nl3.len() != 2 { return 3; };
  if nl3[0] != 1 { return 3; };
  if nl3[1] != 3 { return 3; };
  let nl3b = lines.lines_newline_index("abc");
  if nl3b.len() != 0 { return 3; };

  // Row 4: cursor walk.
  var cur = lines.lines_new("x\ny\nz");
  if cur.line != 0 { return 4; };
  if !_span_is(lines.lines_next(&mut cur), 0, 1) { return 4; };
  if !_span_is(lines.lines_next(&mut cur), 2, 3) { return 4; };
  if !_span_is(lines.lines_next(&mut cur), 4, 5) { return 4; };
  let done4 = lines.lines_next(&mut cur);
  if done4.is_some { return 4; };
  if cur.line != 3 { return 4; };

  // Row 5: materializing line slice.
  let l5 = lines.lines_slice("ab\ncde", 1);
  match l5 {
    Some(text) => {
      if text != "cde" { return 5; };
    },
    None => { return 5; },
  };
  let l5b = lines.lines_slice("ab\ncde", 2);
  if l5b.is_some { return 5; };

  // Row 6: classifiers, part 1 (with mask probes 321 & 0xFF == 65).
  if !ascii.ascii_is_digit(48) { return 6; };
  if ascii.ascii_is_digit(47) { return 6; };
  if ascii.ascii_is_digit(321) { return 6; };
  if !ascii.ascii_is_alpha(321) { return 6; };
  if !ascii.ascii_is_upper(65) { return 6; };
  if !ascii.ascii_is_upper(90) { return 6; };
  if ascii.ascii_is_upper(91) { return 6; };
  if !ascii.ascii_is_lower(122) { return 6; };
  if !ascii.ascii_is_alpha(65) { return 6; };
  if ascii.ascii_is_alpha(91) { return 6; };
  if !ascii.ascii_is_alnum(57) { return 6; };
  if ascii.ascii_is_alnum(45) { return 6; };

  // Row 7: classifiers, part 2.
  if !ascii.ascii_is_space(32) { return 7; };
  if !ascii.ascii_is_space(9) { return 7; };
  if !ascii.ascii_is_space(13) { return 7; };
  if ascii.ascii_is_space(0) { return 7; };
  if !ascii.ascii_is_blank(9) { return 7; };
  if ascii.ascii_is_blank(10) { return 7; };
  if !ascii.ascii_is_hex(70) { return 7; };
  if !ascii.ascii_is_hex(102) { return 7; };
  if ascii.ascii_is_hex(71) { return 7; };
  if !ascii.ascii_is_control(127) { return 7; };
  if ascii.ascii_is_control(32) { return 7; };
  if !ascii.ascii_is_printable(126) { return 7; };
  if ascii.ascii_is_printable(127) { return 7; };

  // Row 8: set membership and case mapping.
  if !ascii.ascii_in_set(59, ";,") { return 8; };
  if ascii.ascii_in_set(46, ";,") { return 8; };
  if ascii.ascii_in_set(0, "") { return 8; };
  if ascii.ascii_upper_byte(97) != 65 { return 8; };
  if ascii.ascii_upper_byte(48) != 48 { return 8; };
  if ascii.ascii_lower_byte(90) != 122 { return 8; };
  if ascii.ascii_lower_byte(321) != 97 { return 8; };

  // Row 9: before/after.
  if split.str_before("a=b=c", "=") != "a" { return 9; };
  if split.str_after("a=b=c", "=") != "b=c" { return 9; };
  if split.str_before("abc", "=") != "abc" { return 9; };
  if split.str_after("abc", "=") != "" { return 9; };
  if split.str_before("abc", "") != "" { return 9; };
  if split.str_after("abc", "") != "abc" { return 9; };

  // Row 10: multi-delimiter scan.
  var delims10 = Vec[Str].new();
  delims10.push("=");
  delims10.push(",");
  let f10 = split.str_find_any_at("k=v,w", &delims10, 0);
  match f10 {
    Some(i) => {
      if i != 1 { return 10; };
    },
    None => { return 10; },
  };
  let f10b = split.str_find_any_at("k=v,w", &delims10, 2);
  match f10b {
    Some(i) => {
      if i != 3 { return 10; };
    },
    None => { return 10; },
  };
  let f10c = split.str_find_any_at("kvw", &delims10, 0);
  if f10c.is_some { return 10; };
  var longest10 = Vec[Str].new();
  longest10.push("=");
  longest10.push("==");
  if split.str_delim_len_at("a==b", &longest10, 1) != 2 { return 10; };
  if split.str_delim_len_at("a==b", &longest10, 0) != 0 { return 10; };

  // Row 11: str_split_spans.
  let sp11 = split.str_split_spans("a,b,", ",");
  if sp11.len() != 6 { return 11; };
  if sp11[0] != 0 || sp11[1] != 1 { return 11; };
  if sp11[2] != 2 || sp11[3] != 3 { return 11; };
  if sp11[4] != 4 || sp11[5] != 4 { return 11; };
  let sp11b = split.str_split_spans("ab", "");
  if sp11b.len() != 4 { return 11; };
  if sp11b[0] != 0 || sp11b[1] != 1 { return 11; };
  if sp11b[2] != 1 || sp11b[3] != 2 { return 11; };
  let sp11c = split.str_split_spans("", ",");
  if sp11c.len() != 2 { return 11; };
  if sp11c[0] != 0 || sp11c[1] != 0 { return 11; };

  // Row 12: str_split_any_spans (longest wins).
  var delims12 = Vec[Str].new();
  delims12.push("=");
  delims12.push("==");
  let sp12 = split.str_split_any_spans("a==b", &delims12);
  if sp12.len() != 4 { return 12; };
  if sp12[0] != 0 || sp12[1] != 1 { return 12; };
  if sp12[2] != 3 || sp12[3] != 4 { return 12; };
  var none12 = Vec[Str].new();
  let sp12b = split.str_split_any_spans("xyz", &none12);
  if sp12b.len() != 2 { return 12; };
  if sp12b[0] != 0 || sp12b[1] != 3 { return 12; };

  // Row 13: StrView basics.
  let s13 = "hello";
  let v13 = view.view_of(s13);
  if view.view_len(&v13) != 5 { return 13; };
  if view.view_is_empty(&v13) { return 13; };
  if view.view_byte_at(&v13, 0) != 104 { return 13; };
  if view.view_byte_at(&v13, 4) != 111 { return 13; };
  if view.view_byte_at(&v13, -1) != 0 { return 13; };
  if view.view_byte_at(&v13, 5) != 0 { return 13; };
  let e13 = view.view_of("");
  if !view.view_is_empty(&e13) { return 13; };

  // Row 14: clamped vs strict windows.
  let c14 = view.view_range("hello", 1, 3);
  if view.view_to_str(&c14) != "ell" { return 14; };
  let c14b = view.view_range("hello", -2, 100);
  if view.view_to_str(&c14b) != "hello" { return 14; };
  let c14c = view.view_range("hello", 9, 2);
  if view.view_len(&c14c) != 0 { return 14; };
  let k14 = view.view_range_checked("hello", 1, 3);
  match k14 {
    Some(ok14) => {
      if view.view_to_str(&ok14) != "ell" { return 14; };
    },
    None => { return 14; },
  };
  let k14b = view.view_range_checked("hello", 1, 5);
  if k14b.is_some { return 14; };
  let k14c = view.view_range_checked("hello", -1, 2);
  if k14c.is_some { return 14; };
  let k14d = view.view_range_checked("hello", 5, 0);
  match k14d {
    Some(ok14d) => {
      if !view.view_is_empty(&ok14d) { return 14; };
    },
    None => { return 14; },
  };

  // Row 15: relative slices, equality, prefix.
  let w15 = view.view_range("hello world", 6, 5);
  let s15 = view.view_slice(&w15, 1, 3);
  if view.view_to_str(&s15) != "orl" { return 15; };
  if !view.view_eq(&w15, &view.view_of("world")) { return 15; };
  if view.view_eq(&view.view_of("world"), &view.view_of("worlds")) { return 15; };
  if !view.view_starts_with(&w15, "wor") { return 15; };
  if view.view_starts_with(&w15, "worlds") { return 15; };
  if !view.view_starts_with(&w15, "") { return 15; };

  // Row 16: search inside a window.
  let f16 = view.view_find(&w15, "r");
  match f16 {
    Some(i) => {
      if i != 2 { return 16; };
    },
    None => { return 16; },
  };
  let f16b = view.view_find(&w15, "world");
  match f16b {
    Some(i) => {
      if i != 0 { return 16; };
    },
    None => { return 16; },
  };
  let f16c = view.view_find(&w15, "x");
  if f16c.is_some { return 16; };
  let f16d = view.view_find(&w15, "");
  match f16d {
    Some(i) => {
      if i != 0 { return 16; };
    },
    None => { return 16; },
  };
  let f16e = view.view_find(&w15, "worlds");
  if f16e.is_some { return 16; };
  let mid16 = view.view_range("aXbXc", 1, 3);
  let f16f = view.view_find(&mid16, "X");
  match f16f {
    Some(i) => {
      if i != 0 { return 16; };
    },
    None => { return 16; },
  };

  // Row 17: strict decode at offsets.
  let cp17 = codepoint.codepoint_at("A", 0);
  match cp17 {
    Some(p) => {
      if p.value != 65 { return 17; };
      if p.byte_len != 1 { return 17; };
      if p.start != 0 { return 17; };
    },
    None => { return 17; },
  };
  let cp17b = codepoint.codepoint_at(_rb2(0xC3, 0xA9), 0);
  match cp17b {
    Some(p) => {
      if p.value != 233 { return 17; };
      if p.byte_len != 2 { return 17; };
    },
    None => { return 17; },
  };
  let cp17c = codepoint.codepoint_at(_rb3(0xE2, 0x82, 0xAC), 0);
  match cp17c {
    Some(p) => {
      if p.value != 8364 { return 17; };
      if p.byte_len != 3 { return 17; };
    },
    None => { return 17; },
  };
  let cp17d = codepoint.codepoint_at(_rb4(0xF0, 0x9F, 0x98, 0x80), 0);
  match cp17d {
    Some(p) => {
      if p.value != 128512 { return 17; };
      if p.byte_len != 4 { return 17; };
    },
    None => { return 17; },
  };
  let cp17e = codepoint.codepoint_at(_rb3(0x61, 0xC3, 0xA9), 1);
  match cp17e {
    Some(p) => {
      if p.value != 233 { return 17; };
      if p.start != 1 { return 17; };
    },
    None => { return 17; },
  };
  let bad17a = codepoint.codepoint_at("A", 1);
  if bad17a.is_some { return 17; };
  let bad17b = codepoint.codepoint_at("A", -1);
  if bad17b.is_some { return 17; };
  let bad17c = codepoint.codepoint_at(_rb1(0xC3), 0);
  if bad17c.is_some { return 17; };
  let bad17d = codepoint.codepoint_at(_rb1(0x80), 0);
  if bad17d.is_some { return 17; };
  let bad17e = codepoint.codepoint_at(_rb2(0xC0, 0x80), 0);
  if bad17e.is_some { return 17; };
  let bad17f = codepoint.codepoint_at(_rb3(0xED, 0xA0, 0x80), 0);
  if bad17f.is_some { return 17; };
  let bad17g = codepoint.codepoint_at(_rb4(0xF4, 0x90, 0x80, 0x80), 0);
  if bad17g.is_some { return 17; };

  // Row 18: cursor walk, offsets, validity.
  let s18 = _rb6(0x61, 0xC3, 0xA9, 0xE2, 0x82, 0xAC);
  var cur18 = codepoint.codepoint_cursor(s18);
  let one18 = codepoint.codepoint_next(&mut cur18);
  match one18 {
    Some(p) => {
      if p.value != 97 { return 18; };
    },
    None => { return 18; },
  };
  let two18 = codepoint.codepoint_next(&mut cur18);
  match two18 {
    Some(p) => {
      if p.value != 233 { return 18; };
      if p.start != 1 { return 18; };
    },
    None => { return 18; },
  };
  let three18 = codepoint.codepoint_next(&mut cur18);
  match three18 {
    Some(p) => {
      if p.value != 8364 { return 18; };
      if p.start != 3 { return 18; };
    },
    None => { return 18; },
  };
  let done18 = codepoint.codepoint_next(&mut cur18);
  if done18.is_some { return 18; };
  let off18 = codepoint.codepoint_offsets(s18);
  if off18.len() != 3 { return 18; };
  if off18[0] != 0 || off18[1] != 1 || off18[2] != 3 { return 18; };
  if !codepoint.codepoints_valid(s18) { return 18; };
  if codepoint.codepoints_valid(_rb2(0x61, 0xC3)) { return 18; };
  if codepoint.codepoints_valid(_rb1(0x80)) { return 18; };
  let off18b = codepoint.codepoint_offsets(_rb4(0x61, 0xC3, 0xA9, 0x80));
  if off18b.len() != 2 { return 18; };
  if off18b[0] != 0 || off18b[1] != 1 { return 18; };
  var cur18b = codepoint.codepoint_cursor(_rb2(0x61, 0xC3));
  let step18 = codepoint.codepoint_next(&mut cur18b);
  if step18.is_none { return 18; };
  let stuck18 = codepoint.codepoint_next(&mut cur18b);
  if stuck18.is_some { return 18; };

  // Row 19: encode KATs.
  var enc19 = Vec[UInt8].new();
  let e19 = codepoint.codepoint_encode(233, &mut enc19);
  if e19.is_err { return 19; };
  if enc19.len() != 2 { return 19; };
  if enc19[0] != 195 { return 19; };
  if enc19[1] != 169 { return 19; };
  var enc19b = Vec[UInt8].new();
  let e19b = codepoint.codepoint_encode(128512, &mut enc19b);
  if e19b.is_err { return 19; };
  if enc19b.len() != 4 { return 19; };
  if enc19b[0] != 240 || enc19b[1] != 159 { return 19; };
  if enc19b[2] != 152 || enc19b[3] != 128 { return 19; };
  var enc19c = Vec[UInt8].new();
  let e19c = codepoint.codepoint_encode(0, &mut enc19c);
  if e19c.is_err { return 19; };
  if enc19c.len() != 1 || enc19c[0] != 0 { return 19; };
  var enc19d = Vec[UInt8].new();
  let e19d = codepoint.codepoint_encode(55296, &mut enc19d);
  if e19d.is_ok { return 19; };
  let e19e = codepoint.codepoint_encode(1114112, &mut enc19d);
  if e19e.is_ok { return 19; };
  let e19f = codepoint.codepoint_encode(-1, &mut enc19d);
  if e19f.is_ok { return 19; };
  if codepoint.codepoint_byte_len(65) != 1 { return 19; };
  if codepoint.codepoint_byte_len(233) != 2 { return 19; };
  if codepoint.codepoint_byte_len(8364) != 3 { return 19; };
  if codepoint.codepoint_byte_len(128512) != 4 { return 19; };
  if codepoint.codepoint_byte_len(55296) != 0 { return 19; };
  if !codepoint.codepoint_valid(0) { return 19; };
  if codepoint.codepoint_valid(1114112) { return 19; };

  // Row 20: code-point vector -> Str.
  var cps20 = Vec[Int].new();
  cps20.push(72);
  cps20.push(233);
  cps20.push(8364);
  let r20 = codepoint.str_from_codepoints(&cps20);
  match r20 {
    Ok(built20) => {
      if built20.len() != 6 { return 20; };
      if built20 != _rb6(0x48, 0xC3, 0xA9, 0xE2, 0x82, 0xAC) { return 20; };
    },
    Err(_) => { return 20; },
  };
  var cps20b = Vec[Int].new();
  cps20b.push(65);
  cps20b.push(0);
  cps20b.push(66);
  let r20b = codepoint.str_from_codepoints(&cps20b);
  if r20b.is_ok { return 20; };
  var cps20c = Vec[Int].new();
  cps20c.push(65);
  cps20c.push(1114112);
  let r20c = codepoint.str_from_codepoints(&cps20c);
  if r20c.is_ok { return 20; };
  var cps20d = Vec[Int].new();
  let r20d = codepoint.str_from_codepoints(&cps20d);
  match r20d {
    Ok(empty20) => {
      if empty20.len() != 0 { return 20; };
    },
    Err(_) => { return 20; },
  };
  var cps20e = Vec[Int].new();
  cps20e.push(128512);
  let r20e = codepoint.str_from_codepoints(&cps20e);
  match r20e {
    Ok(built20e) => {
      if !codepoint.codepoints_valid(built20e) { return 20; };
      let back20 = codepoint.codepoint_offsets(built20e);
      if back20.len() != 1 { return 20; };
    },
    Err(_) => { return 20; },
  };

  // Row 21: dependency-free builder materializer.
  var b21 = builder.sb_new();
  builder.sb_push_byte(&mut b21, 104);
  builder.sb_push_byte(&mut b21, 105);
  let t21 = builder.sb_into_str(b21);
  if t21.len() != 2 { return 21; };
  if t21 != "hi" { return 21; };
  var b21b = builder.sb_new();
  builder.sb_push_byte(&mut b21b, 104);
  builder.sb_push_byte(&mut b21b, 0);
  builder.sb_push_byte(&mut b21b, 105);
  let t21b = builder.sb_into_str(b21b);
  if t21b.len() != 1 { return 21; };
  if t21b != "h" { return 21; };
  var b21c = builder.sb_new();
  let t21c = builder.sb_into_str(b21c);
  if t21c.len() != 0 { return 21; };

  return 0;
}
