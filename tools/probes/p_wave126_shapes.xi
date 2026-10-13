// p_wave126_shapes.xi -- wave 126 lock: the strnlen-family batch 2
// (string.xi cached (base, len) conversions: trim / words / char_count /
// title_case / swap_case / reverse / truncate_utf8 plus the str_escape /
// str_unescape Vec-builders) and the json-escape family (convert/json,
// serialize, serialize/json, log/json). Byte-exact semantics on every
// converted path, including multibyte, truncated and malformed sequences.
// The serialize.json control-char hex rows are RED pre-fix (the decimal
// int_to_string nibble path emitted 11/14/15 for nibbles above 9) and green
// post with correct lowercase \u00XX hex. Values returned from the module
// surface are bound before comparing. Returns 0 when every case holds.

module p_wave126_shapes

use xiom.string;
use xiom.string.escape;
use xiom.convert.json as cjson;
use xiom.serialize as ser;
use xiom.serialize.json as sjson;

fn main() -> Int {
  // ---- str_trim: decoded-char whitespace (32 / 9 / 10 / 13 only) ----
  let t1 = string.str_trim("  hi\t");
  if t1 != "hi" { return 1; }
  let t2 = string.str_trim(" \r\nhi \t\r\n");
  if t2 != "hi" { return 2; }
  let t3 = string.str_trim(" \t ");
  if t3 != "" { return 3; }
  let t4 = string.str_trim("");
  if t4 != "" { return 4; }
  let nb = mk2(0xC2, 0xA0);  // NBSP: not whitespace for the char predicate
  let t5 = string.str_trim(string.str_concat(" ", string.str_concat(nb, " ")));
  if t5 != nb { return 5; }
  let t6 = string.str_trim(nb);
  if t6 != nb { return 6; }

  // ---- words ----
  let w1 = string.words(" \t\r\n a b\n c ");
  if w1.len() != 3 { return 7; }
  let wa = w1[0];
  let wb = w1[1];
  let wc = w1[2];
  if wa != "a" { return 8; }
  if wb != "b" { return 9; }
  if wc != "c" { return 10; }
  let w2 = string.words("");
  if w2.len() != 0 { return 11; }
  let w3 = string.words(" \t ");
  if w3.len() != 0 { return 12; }
  let w4 = string.words(mk2(0xC3, 0xA9));
  if w4.len() != 1 { return 13; }
  let wd = w4[0];
  if wd != mk2(0xC3, 0xA9) { return 14; }

  // ---- char_count ----
  if string.char_count("abc") != 3 { return 15; }
  if string.char_count("") != 0 { return 16; }
  if string.char_count(mk2(0xC3, 0xA9)) != 1 { return 17; }
  if string.char_count(mk1(0xC3)) != 1 { return 18; }
  if string.char_count(mk1(0x80)) != 1 { return 19; }
  if string.char_count(mk4(0xF0, 0x9F, 0x98, 0x80)) != 1 { return 20; }

  // ---- str_escape (string.xi core + the escape delegator) ----
  let e1 = string.str_escape("a\nb\t\"c\\d\re");
  if e1 != "a\\nb\\t\\\"c\\\\d\\re" { return 21; }
  let e2 = string.str_escape("");
  if e2 != "" { return 22; }
  let e3 = string.str_escape(mk2(0xC3, 0xA9));  // well-formed multibyte passthrough
  if e3 != mk2(0xC3, 0xA9) { return 23; }
  let e4 = string.str_escape(mk1(0xC3));  // truncated lead byte re-encodes C3 83
  if e4 != mk2(0xC3, 0x83) { return 24; }
  let e5 = string.str_escape(mk1(0x80));  // stray continuation re-encodes C2 80
  if e5 != mk2(0xC2, 0x80) { return 25; }
  let e6 = string.str_escape(mk1(0x0B));  // other control bytes pass through
  if e6 != mk1(0x0B) { return 26; }
  let e7 = escape.str_escape("x\ny");
  if e7 != "x\\ny" { return 27; }

  // ---- str_unescape ----
  let u1 = string.str_unescape("a\\nb\\tc\\rd");
  if u1 != "a\nb\tc\rd" { return 28; }
  let u2 = string.str_unescape("\\\"q\\\\r");
  if u2 != "\"q\\r" { return 29; }
  let u3 = string.str_unescape("a\\q");  // unknown escape kept verbatim
  if u3 != "a\\q" { return 30; }
  let u4 = string.str_unescape("abc\\");  // trailing backslash kept
  if u4 != "abc\\" { return 31; }
  let u5 = string.str_unescape("");
  if u5 != "" { return 32; }
  let u6 = string.str_unescape(string.str_concat(mk2(0xC3, 0xA9), "\\n"));
  if u6 != string.str_concat(mk2(0xC3, 0xA9), "\n") { return 33; }

  // ---- title / swap case (ASCII-only mapping, byte truncation by design) ----
  let c1 = string.str_title_case("hello WORLD");
  if c1 != "Hello World" { return 34; }
  let c2 = string.str_title_case("  x  y");
  if c2 != "  X  Y" { return 35; }
  let c3 = string.str_title_case(string.str_concat(mk2(0xC3, 0xA9), "a"));
  if c3 != mk3(0xE9, 0xA9, 0x61) { return 36; }
  let s1 = string.str_swap_case("aB cD");
  if s1 != "Ab Cd" { return 37; }
  let s2 = string.str_swap_case(mk2(0xC3, 0xA9));
  if s2 != mk2(0xE9, 0xA9) { return 38; }

  // ---- reverse (character boundaries; byte length preserved) ----
  let r1 = string.str_reverse("abc");
  if r1 != "cba" { return 39; }
  let r2 = string.str_reverse("");
  if r2 != "" { return 40; }
  let r3 = string.str_reverse(mk2(0xC3, 0xA9));
  if r3 != mk2(0xC3, 0xA9) { return 41; }
  let r4 = string.str_reverse(string.str_concat("a", mk2(0xC3, 0xA9)));
  if r4 != string.str_concat(mk2(0xC3, 0xA9), "a") { return 42; }
  let r5 = string.str_reverse("aba");
  if r5 != "aba" { return 43; }

  // ---- truncate_utf8 (never splits a sequence) ----
  let q1 = string.str_truncate_utf8("abc", 2);
  if q1 != "ab" { return 44; }
  let q2 = string.str_truncate_utf8(string.str_concat(mk2(0xC3, 0xA9), "a"), 1);
  if q2 != "" { return 45; }
  let q3 = string.str_truncate_utf8(string.str_concat(mk2(0xC3, 0xA9), "a"), 2);
  if q3 != mk2(0xC3, 0xA9) { return 46; }
  let q4 = string.str_truncate_utf8(string.str_concat(mk2(0xC3, 0xA9), "a"), 3);
  if q4 != string.str_concat(mk2(0xC3, 0xA9), "a") { return 47; }
  let q5 = string.str_truncate_utf8("abc", 0);
  if q5 != "" { return 48; }
  let q6 = string.str_truncate_utf8("abc", 10);
  if q6 != "abc" { return 49; }
  let q7 = string.str_truncate_utf8("abc", 0 - 1);
  if q7 != "" { return 50; }

  // ---- convert.json escape / unescape ----
  let j1 = cjson.json_escape("a\"b\n");
  if j1 != "a\\\"b\\n" { return 51; }
  let j2 = cjson.json_escape(mk1(0x0B));  // reference: named escapes only
  if j2 != mk1(0x0B) { return 52; }
  let j3 = cjson.json_escape("");
  if j3 != "" { return 53; }
  let j4 = cjson.json_unescape("\\u00e9");
  match j4 {
    Ok(v4) => { if v4 != mk2(0xC3, 0xA9) { return 54; } },
    Err(_) => { return 55; },
  }
  let j5 = cjson.json_unescape("\\q");
  if j5.is_ok { return 56; }
  let j6 = cjson.json_unescape("\\u00");
  if j6.is_ok { return 57; }
  let j7 = cjson.json_unescape("\\uZZZZ");
  if j7.is_ok { return 58; }

  // ---- serialize parent escape (named escapes only) ----
  let p1 = ser.json_escape("a\"b");
  if p1.len() < 3 { return 59; }
  let p2 = ser.json_escape(mk1(0x0B));
  if p2 != mk1(0x0B) { return 60; }

  // ---- serialize.json escape: control bytes as lowercase \u00XX ----
  let s1j = sjson.json_escape("a\tb");
  if s1j != "a\\tb" { return 61; }
  let s2j = sjson.json_escape("/");
  if s2j != "\\/" { return 62; }
  let s3j = sjson.json_escape(mk1(0x01));
  if s3j != "\\u0001" { return 63; }
  let s7j = sjson.json_escape(mk4(0xF0, 0x9F, 0x98, 0x80));
  if s7j != mk4(0xF0, 0x9F, 0x98, 0x80) { return 64; }
  // RED pre-fix rows: nibbles above 9 must render as hex digits a..f
  let s4j = sjson.json_escape(mk1(0x0B));
  if s4j != "\\u000b" { return 65; }
  let s5j = sjson.json_escape(mk1(0x0E));
  if s5j != "\\u000e" { return 66; }
  let s6j = sjson.json_escape(mk1(0x1E));
  if s6j != "\\u001e" { return 67; }

  // ---- reverse: truncated trailing sequences terminate (raw-copy tail) ----
  let r6 = string.str_reverse(mk1(0xC3));
  if r6 != mk1(0xC3) { return 68; }
  let r7 = string.str_reverse(string.str_concat("abc", mk1(0xC3)));
  if r7 != string.str_concat(mk1(0xC3), "cba") { return 69; }
  let r8 = string.str_reverse(mk2(0x80, 0x80));  // boundary at len: re-encode
  if r8 != mk2(0xC2, 0x80) { return 70; }

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
