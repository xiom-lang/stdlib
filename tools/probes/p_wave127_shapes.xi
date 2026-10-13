// p_wave127_shapes.xi -- wave 127 lock: the strnlen-family batch 3 -- the
// remaining per-position string accessors (case/collate/reverse/replace/
// unescape/truncate/segment/sentencebreak/shuffle/wordbreak/indent/unicode)
// now read through cached raw pointers instead of the runtime byte_at /
// char_at accessors (which strnlen the whole string per call). Byte-exact
// semantics on every converted path: multibyte, malformed and out-of-range
// rows included. Values returned from the module surface are bound before
// comparing. Returns 0 when every case holds.

module p_wave127_shapes

use xiom.string;
use xiom.string.case as scase;
use xiom.string.collate as scoll;
use xiom.string.reverse as srev;
use xiom.string.replace as srep;
use xiom.string.unescape as sunesc;
use xiom.string.truncate as strunc;
use xiom.string.segment as sseg;
use xiom.string.sentencebreak as ssb;
use xiom.string.shuffle as ssh;
use xiom.string.wordbreak as swb;
use xiom.string.indent as sind;
use xiom.string.unicode as suni;

fn main() -> Int {
  // ---- case: word split + case forms ----
  let c1 = scase.str_capitalize("hello");
  if c1 != "Hello" { return 1; }
  let c2 = scase.str_capitalize("");
  if c2 != "" { return 2; }
  let c3 = scase.str_capitalize(mk2(0xC3, 0xA9));
  if c3 != mk2(0xC3, 0xA9) { return 3; }
  let c4 = scase.str_sentence_case("one. two! three");
  if c4 != "One. Two! Three" { return 4; }
  let c5 = scase.str_sentence_case(string.str_concat(mk2(0xC3, 0xA9), ". x"));
  if c5 != string.str_concat(mk2(0xC3, 0xA9), ". X") { return 5; }
  let c6 = scase.str_sentence_case("");
  if c6 != "" { return 6; }
  let c7 = scase.str_to_camel_case("hello_world");
  if c7 != "helloWorld" { return 7; }
  let c8 = scase.str_to_snake_case("helloWorld");
  if c8 != "hello_world" { return 8; }
  let c9 = scase.str_to_kebab_case("helloWorld");
  if c9 != "hello-world" { return 9; }
  let c10 = scase.str_to_pascal_case("hello_world");
  if c10 != "HelloWorld" { return 10; }
  let c11 = scase.str_to_camel_case("HelloWorld");
  if c11 != "helloWorld" { return 11; }
  let c12 = scase.str_to_snake_case("hello_world");
  if c12 != "hello_world" { return 12; }

  // ---- collate ----
  let k1 = scoll.collate_compare("a", "b");
  if k1 != 0 - 1 { return 13; }
  let k2 = scoll.collate_compare("b", "a");
  if k2 != 1 { return 14; }
  let k3 = scoll.collate_compare("ab", "ab");
  if k3 != 0 { return 15; }
  let k4 = scoll.collate_compare(mk2(0xC3, 0xA9), mk1(0xFF));
  if k4 != 0 - 1 { return 16; }
  let k5 = scoll.collate_compare(mk1(0x80), "a");
  if k5 != 1 { return 17; }
  let k6 = scoll.collate_key("AbC");
  if k6 != "abc" { return 18; }

  // ---- reverse ----
  let r1 = srev.str_reverse("abc");
  if r1 != "cba" { return 19; }
  let r2 = srev.str_reverse(string.str_concat(mk2(0xC3, 0xA9), "a"));
  if r2 != string.str_concat("a", mk2(0xC3, 0xA9)) { return 20; }
  let r3 = srev.str_reverse(string.str_concat("abc", mk1(0xC3)));
  if r3 != string.str_concat(mk1(0xC3), "cba") { return 21; }
  let r4 = srev.str_reverse_chars("");
  if r4 != "" { return 22; }
  let r5 = srev.str_reverse_words("a b  c");
  if r5 != "c  b a" { return 23; }
  let r6 = srev.str_reverse_words("   ");
  if r6 != "   " { return 24; }
  let r7 = srev.str_reverse("aba");
  if r7 != "aba" { return 25; }

  // ---- replace ----
  let p1 = srep.str_replace("aXbXc", "X", "-");
  if p1 != "a-b-c" { return 26; }
  let p2 = srep.str_replace("abc", "", "z");
  if p2 != "abc" { return 27; }
  let p3 = srep.str_replace(string.str_concat(mk2(0xC3, 0xA9), mk2(0xC3, 0xA9)), mk2(0xC3, 0xA9), "x");
  if p3 != "xx" { return 28; }
  let p4 = srep.str_replace_first("aaa", "a", "b");
  if p4 != "baa" { return 29; }
  let p5 = srep.str_replace_last("aaa", "a", "b");
  if p5 != "aab" { return 30; }
  let p6 = srep.str_replace_n("aaa", "a", "b", 2);
  if p6 != "bba" { return 31; }
  let p7 = srep.str_replace_n("aaa", "a", "b", 0);
  if p7 != "aaa" { return 32; }
  let p8 = srep.str_replace_all("hello world", "world", "there");
  if p8 != "hello there" { return 33; }

  // ---- unescape ----
  let u1 = sunesc.str_unescape("a\\nb");
  if u1 != "a\nb" { return 34; }
  let u2 = sunesc.str_unescape("a\\qb");
  if u2 != "a\\qb" { return 35; }
  let u3 = sunesc.str_unescape("abc\\");
  if u3 != "abc\\" { return 36; }
  let u4 = sunesc.str_unescape(string.str_concat(mk2(0xC3, 0xA9), "\\t"));
  if u4 != string.str_concat(mk2(0xC3, 0xA9), "\t") { return 37; }
  let u5 = sunesc.str_unescape_ascii("a\\x41b");
  if u5 != "aAb" { return 38; }
  let u6 = sunesc.str_unescape_ascii("a\\xZZb");
  if u6 != "a\\xZZb" { return 39; }
  let u7 = sunesc.str_unescape_ascii("a\\x4");
  if u7 != "a\\x4" { return 40; }
  let u8 = sunesc.str_unescape_unicode("\\u0041");
  if u8 != "A" { return 41; }
  let u9 = sunesc.str_unescape_unicode("\\u00e9");
  if u9 != mk2(0xC3, 0xA9) { return 42; }
  let u10 = sunesc.str_unescape_unicode("\\uZZZZ");
  if u10 != "\\uZZZZ" { return 43; }
  let u11 = sunesc.str_unescape_unicode("\\U0001F600");
  if u11 != mk4(0xF0, 0x9F, 0x98, 0x80) { return 44; }

  // ---- truncate ----
  let t1 = strunc.str_truncate("abc", 2);
  if t1 != "ab" { return 45; }
  let t2 = strunc.str_truncate(string.str_concat(mk2(0xC3, 0xA9), "a"), 1);
  if t2 != mk2(0xC3, 0xA9) { return 46; }
  let emoji = mk4(0xF0, 0x9F, 0x98, 0x80);
  let t3 = strunc.str_truncate(string.str_concat(emoji, "b"), 1);
  if t3 != emoji { return 47; }
  let t4 = strunc.str_truncate("abc", 0);
  if t4 != "" { return 48; }
  let t5 = strunc.str_truncate_middle("abcdef", 4);
  if t5 != "abef" { return 49; }
  let t6 = strunc.str_truncate_middle(string.str_concat("a", string.str_concat(mk2(0xC3, 0xA9), "b")), 2);
  if t6 != mk3(0x61, 0xC3, 0xA9) { return 50; }
  let t7 = strunc.str_truncate_with_ellipsis("abcdef", 5);
  if t7 != "ab..." { return 51; }
  let t8 = strunc.str_truncate_utf8(string.str_concat(mk2(0xC3, 0xA9), "a"), 1);
  if t8 != "" { return 52; }

  // ---- segment ----
  let g1 = sseg.unicode_grapheme_clusters("abc");
  if g1.len() != 3 { return 53; }
  let combining = mk2(0xCC, 0x81);
  let g2 = sseg.unicode_grapheme_clusters(string.str_concat("a", string.str_concat(combining, "b")));
  if g2.len() != 2 { return 54; }
  let ga = g2[0];
  let gb = g2[1];
  if ga != mk3(0x61, 0xCC, 0x81) { return 55; }
  if gb != "b" { return 56; }
  let g3 = sseg.unicode_grapheme_clusters("a\r\nb");
  if g3.len() != 3 { return 57; }
  let g3b = g3[1];
  if g3b != "\r\n" { return 58; }
  let offs = sseg.unicode_segment_graphemes(string.str_concat("a", string.str_concat(combining, "b")));
  if offs.len() != 3 { return 59; }
  let o0 = offs[0];
  let o1 = offs[1];
  let o2 = offs[2];
  if o0 != 0 { return 60; }
  if o1 != 3 { return 61; }
  if o2 != 4 { return 62; }
  let g4 = sseg.unicode_grapheme_clusters(mk1(0x80));
  if g4.len() != 1 { return 63; }

  // ---- sentencebreak ----
  let s1 = ssb.unicode_sentence_boundaries("One. Two");
  if s1.len() != 1 { return 64; }
  let s1b = s1[0];
  if s1b != 5 { return 65; }
  let s2 = ssb.unicode_sentence_boundaries("3.14");
  if s2.len() != 0 { return 66; }
  let s3 = ssb.unicode_sentence_boundaries("\n\n");
  if s3.len() != 1 { return 67; }
  let s4 = ssb.unicode_sentence_boundaries("A.\nB");
  if s4.len() != 1 { return 68; }
  let s4b = s4[0];
  if s4b != 2 { return 69; }
  let s5 = ssb.unicode_split_sentences("One. Two");
  if s5.len() != 2 { return 70; }
  let s5a = s5[0];
  if s5a != "One. " { return 71; }
  let s5b = s5[1];
  if s5b != "Two" { return 72; }

  // ---- shuffle ----
  let sh1 = ssh.str_shuffle_seeded("abcd", 1);
  if sh1.len() != 4 { return 73; }
  if !string.str_contains(sh1, "a") { return 74; }
  if !string.str_contains(sh1, "b") { return 75; }
  if !string.str_contains(sh1, "c") { return 76; }
  if !string.str_contains(sh1, "d") { return 77; }
  let sh2 = ssh.str_shuffle_seeded("", 1);
  if sh2 != "" { return 78; }
  let sh3 = ssh.str_shuffle_words("a b c");
  if sh3.len() != 5 { return 79; }
  if !string.str_contains(sh3, "a") { return 80; }
  if !string.str_contains(sh3, "c") { return 81; }

  // ---- wordbreak ----
  let w1 = swb.unicode_word_boundaries("Hello,world");
  if w1.len() != 2 { return 82; }
  let w1a = w1[0];
  let w1b = w1[1];
  if w1a != 5 { return 83; }
  if w1b != 6 { return 84; }
  let w2 = swb.unicode_split_words("Hello,world");
  if w2.len() != 3 { return 85; }
  let w2a = w2[0];
  let w2b = w2[1];
  let w2c = w2[2];
  if w2a != "Hello" { return 86; }
  if w2b != "," { return 87; }
  if w2c != "world" { return 88; }
  let w3 = swb.unicode_word_boundaries("don't");
  if w3.len() != 0 { return 89; }
  let w4 = swb.unicode_word_boundaries("3.14");
  if w4.len() != 0 { return 90; }
  let w5 = swb.unicode_split_words("a b");
  if w5.len() != 2 { return 91; }
  let w5a = w5[0];
  if w5a != "a " { return 92; }

  // ---- indent ----
  let i1 = sind.str_indent("a\nb", 2);
  if i1 != "  a\n  b" { return 93; }
  let i2 = sind.str_dedent("  a\n    b");
  if i2 != "a\n  b" { return 94; }
  let i3 = sind.str_unindent("\ta\n  b\nc");
  if i3 != "a\nb\nc" { return 95; }
  let i4 = sind.str_indent("a", 0);
  if i4 != "a" { return 96; }
  let i5 = sind.str_dedent("a\nb");
  if i5 != "a\nb" { return 97; }

  // ---- unicode (decode-loop owners) ----
  let n1 = suni.unicode_tolower_full("ABC");
  if n1 != "abc" { return 98; }
  let n2 = suni.unicode_tolower_full(mk2(0xC3, 0x89));  // U+00C9 -> U+00E9
  if n2 != mk2(0xC3, 0xA9) { return 99; }
  let n3 = suni.unicode_toupper_full("abc");
  if n3 != "ABC" { return 100; }
  let n4 = suni.unicode_grapheme_count(string.str_concat("a", string.str_concat(combining, "b")));
  if n4 != 2 { return 101; }
  let n5 = suni.unicode_combining_sequence("abc");
  if n5.len() != 1 { return 102; }
  let n5a = n5[0];
  if n5a != "abc" { return 105; }
  let n6 = suni.unicode_combining_sequence(string.str_concat("a", string.str_concat(combining, "b")));
  if n6.len() != 2 { return 103; }
  let n6a = n6[0];
  if n6a != mk3(0x61, 0xCC, 0x81) { return 104; }

  // ---- string.xi bare-byte_at tail (scan + builder conversions) ----
  let x1 = string.str_compare("a", "b");
  if x1 != 0 - 1 { return 106; }
  let x2 = string.str_compare("b", "a");
  if x2 != 1 { return 107; }
  let x3 = string.str_compare("ab", "ab");
  if x3 != 0 { return 108; }
  let x4 = string.str_compare(mk1(0xC3), "a");  // unsigned byte compare (0xC3 > 'a')
  if x4 != 1 { return 109; }
  let x5 = string.str_split("a,b,c", ",");
  if x5.len() != 3 { return 110; }
  let x5b = x5[1];
  if x5b != "b" { return 111; }
  let x6 = string.str_split("a,,b", ",");
  if x6.len() != 3 { return 112; }
  let x6b = x6[1];
  if x6b != "" { return 113; }
  let x7 = string.str_split("ab", "");
  if x7.len() != 2 { return 114; }
  if !string.str_contains("hello", "ell") { return 115; }
  if string.str_contains("abc", "z") { return 116; }
  if !string.str_starts_with("abc", "ab") { return 117; }
  if !string.str_ends_with("abc", "bc") { return 118; }
  let y1 = string.str_upper(mk3(0xC3, 0xA9, 0x61));  // multibyte passthrough + a->A
  if y1 != mk3(0xC3, 0xA9, 0x41) { return 119; }
  let y2 = string.str_lower("AbC");
  if y2 != "abc" { return 120; }
  let y3 = string.str_translate("hello", "el", "ip");
  if y3 != "hippo" { return 121; }
  let y4 = string.str_translate("abc", "abc", "xy");
  if y4 != "xy" { return 122; }
  let y5 = string.str_rot47("ABC");
  if y5 != "pqr" { return 123; }
  let y6 = string.str_caesar("abz", 1);
  if y6 != "bca" { return 124; }
  let y7 = string.str_caesar("abc", 0 - 1);
  if y7 != "zab" { return 125; }
  let y8 = string.str_atbash("azAZ");
  if y8 != "zaZA" { return 126; }

  return 0;
}

// mk1 builds a 1-byte string from a raw byte value.
fn mk1(a: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(a as UInt8);
  Str::from_utf8(v)
}

// mk2 builds a 2-byte string from raw byte values.
fn mk2(a: Int, b: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  Str::from_utf8(v)
}

// mk3 builds a 3-byte string from raw byte values.
fn mk3(a: Int, b: Int, c: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  v.push(c as UInt8);
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
