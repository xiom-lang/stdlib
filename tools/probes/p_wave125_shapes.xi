// p_wave125_shapes.xi -- wave 125 lock: the strnlen-family conversion batch
// (compare / trim / escape raw-byte loops over cached (base, len) views) plus
// the escape Vec-builder rewrite. Byte-exact semantics on every converted
// path, including multibyte folding (ASCII-only), natural-order digit runs
// with leading zeros, out-of-range guards, and truncated UTF-8 sequences.
// Returns 0 when all cases hold. Red pre-fix is semantic (the conversions
// must not change any byte); green post.

module p_wave125_shapes

use xiom.string;
use xiom.string.compare;
use xiom.string.trim;
use xiom.string.escape;
use xiom.io;

fn main() -> Int {
  // --- compare: case folding is ASCII-only and byte-exact ---
  let c1 = compare.str_compare_ignore_case("AbC", "aBc");
  if c1 != 0 {
    return 1;
  }
  let c2 = compare.str_compare_ignore_case("abc", "abd");
  if c2 != -1 {
    return 2;
  }
  let c3 = compare.str_compare_ignore_case("abd", "abc");
  if c3 != 1 {
    return 3;
  }
  let c4 = compare.str_eq_ignore_case("XyZ", "xYz");
  if c4 != true {
    return 4;
  }
  // multibyte: only ASCII letters fold, so e-acute > E-acute (169 vs 137)
  let lower_e = mk2(195, 169);
  let upper_e = mk2(195, 137);
  let c5 = compare.str_compare_ignore_case(lower_e, upper_e);
  if c5 != 1 {
    return 5;
  }
  let c6 = compare.str_compare_ignore_case(lower_e, lower_e);
  if c6 != 0 {
    return 6;
  }
  // empty / prefix cases
  let c7 = compare.str_compare_ignore_case("", "");
  if c7 != 0 {
    return 7;
  }
  let c8 = compare.str_compare_ignore_case("", "a");
  if c8 != -1 {
    return 8;
  }
  let c9 = compare.str_compare_ignore_case("a", "");
  if c9 != 1 {
    return 9;
  }

  // --- natural order ---
  let n1 = compare.str_compare_natural("x2", "x10");
  if n1 != -1 {
    return 10;
  }
  let n2 = compare.str_compare_natural("x10", "x2");
  if n2 != 1 {
    return 11;
  }
  let n3 = compare.str_compare_natural("x02", "x2");
  if n3 != 1 {
    return 12;
  }
  let n3b = compare.str_compare_natural("x2", "x02");
  if n3b != -1 {
    return 12;
  }
  let n4 = compare.str_compare_natural("a2b", "a2b");
  if n4 != 0 {
    return 13;
  }
  let n5 = compare.str_compare_natural("x010", "x0010");
  if n5 != -1 {
    return 14;
  }
  let n6 = compare.str_compare_natural("", "");
  if n6 != 0 {
    return 15;
  }

  // --- trim ---
  let t1 = trim.str_trim_start(" \t\r\nhi ");
  if t1 != "hi " {
    return 16;
  }
  let t2 = trim.str_trim_end(" hi \t\r\n");
  if t2 != " hi" {
    return 17;
  }
  let t3 = trim.str_trim_matches("xxhixx", "x");
  if t3 != "hi" {
    return 18;
  }
  let t4 = trim.str_trim_start_matches("--a--", "-");
  if t4 != "a--" {
    return 19;
  }
  let t5 = trim.str_trim_end_matches("--a--", "-");
  if t5 != "--a" {
    return 20;
  }
  let t6 = trim.str_trim_matches("abc", "");
  if t6 != "abc" {
    return 21;
  }
  let t7 = trim.str_trim_start("\t\t");
  if t7 != "" {
    return 22;
  }
  let t8 = trim.str_trim_end("");
  if t8 != "" {
    return 23;
  }

  // --- escape: ascii + unicode + truncated sequence ---
  let e1 = escape.str_escape_ascii("plain");
  if e1 != "plain" {
    return 24;
  }
  let e2 = escape.str_escape_ascii(lower_e);
  if e2 != "\\xc3\\xa9" {
    return 25;
  }
  let e3 = escape.str_escape_unicode(lower_e);
  if e3 != "\\u00e9" {
    return 26;
  }
  let emoji = mk4(240, 159, 152, 128); // U+1F600
  let e4 = escape.str_escape_unicode(emoji);
  if e4 != "\\uf600" {
    return 27;
  }
  // truncated 2-byte sequence: leading byte alone reads the missing
  // continuation as 0 (the old runtime byte_at clamp), giving c0
  let truncated = string.str_slice(lower_e, 0, 1);
  let e5 = escape.str_escape_unicode(truncated);
  if e5 != "\\u00c0" {
    return 28;
  }
  let e6 = escape.str_escape_ascii(truncated);
  if e6 != "\\xc3" {
    return 29;
  }
  let e7 = escape.str_escape_ascii("");
  if e7 != "" {
    return 30;
  }
  let e8 = escape.str_escape_unicode("");
  if e8 != "" {
    return 31;
  }

  // --- trimmed lengths on a big-ish input stay exact ---
  var big = "ab";
  while big.len() < 4096 {
    big = string.str_concat(big, big);
  }
  let padded = string.str_concat(" ", big);
  let tp = trim.str_trim_start(padded);
  if tp.len() != big.len() {
    return 32;
  }
  let cmp_big = compare.str_compare_ignore_case(big, big);
  if cmp_big != 0 {
    return 33;
  }
  return 0;
}

// mk2 builds a 2-byte string from raw byte values.
fn mk2(a: Int, b: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  Str::from_utf8(v)
}

// mk4 builds a 4-byte string from raw byte values.
fn mk4(a: Int, b: Int, c: Int, d: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  v.push(c as UInt8);
  v.push(d as UInt8);
  Str::from_utf8(v)
}
