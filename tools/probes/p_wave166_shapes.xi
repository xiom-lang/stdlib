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
// Setup failures use 20+.

module p_wave166_shapes

use xiom.string;
use xiom.string.lines;
use xiom.string.ascii;
use xiom.string.split;

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

  return 0;
}
