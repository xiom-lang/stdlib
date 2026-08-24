// kat_convert_utf8_decoder.xi -- UTF-8 decoder known-answer tests
// Valid sequences (Markus Kuhn UTF-8 stress class + Unicode boundaries) must
// decode to the exact codepoint; malformed sequences (overlongs, surrogate
// halves, bare continuations, truncations, > U+10FFFF) must be REJECTED.
module kat_convert_utf8_decoder
use xiom.convert.utf8;
use xiom.convert;
use xiom.io;

fn seq1(a: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(a as UInt8);
  return v;
}
fn seq2(a: Int, b: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  return v;
}
fn seq3(a: Int, b: Int, c: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  v.push(c as UInt8);
  return v;
}
fn seq4(a: Int, b: Int, c: Int, d: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  v.push(c as UInt8);
  v.push(d as UInt8);
  return v;
}

// returns 0 if decoded codepoint == want_cp, else code
fn expect_cp(tag: Str, s: Vec[UInt8], want_cp: Int, code: Int) -> Int {
  match utf8.utf8_decode(&s) {
    Some(c) => {
      var got = convert.char_to_int(c);
      if got != want_cp {
        io.println("utf8 " + tag + ": wrong codepoint");
        return code;
      }
      return 0;
    },
    None => { io.println("utf8 " + tag + ": rejected valid sequence"); return code; },
  }
}

fn expect_reject(tag: Str, s: Vec[UInt8], code: Int) -> Int {
  if utf8.utf8_decode(&s).is_some {
    io.println("utf8 " + tag + ": accepted malformed sequence");
    return code;
  }
  return 0;
}

fn main() -> Int {
  // ---- valid sequences ----
  var r = expect_cp("ascii A", seq1(0x41), 0x41, 1);
  if r != 0 { return r; }

  r = expect_cp("boundary 0x7F", seq1(0x7F), 0x7F, 2);
  if r != 0 { return r; }

  r = expect_cp("2-byte U+00E9", seq2(0xC3, 0xA9), 0xE9, 3);
  if r != 0 { return r; }

  r = expect_cp("3-byte U+20AC", seq3(0xE2, 0x82, 0xAC), 0x20AC, 4);
  if r != 0 { return r; }

  r = expect_cp("4-byte U+10000", seq4(0xF0, 0x90, 0x80, 0x80), 0x10000, 5);
  if r != 0 { return r; }

  r = expect_cp("max U+10FFFF", seq4(0xF4, 0x8F, 0xBF, 0xBF), 0x10FFFF, 6);
  if r != 0 { return r; }

  // ---- malformed sequences MUST be rejected ----
  r = expect_reject("overlong slash C0 AF", seq2(0xC0, 0xAF), 7);
  if r != 0 { return r; }

  r = expect_reject("overlong E0 80 80", seq3(0xE0, 0x80, 0x80), 8);
  if r != 0 { return r; }

  r = expect_reject("surrogate half ED A0 80", seq3(0xED, 0xA0, 0x80), 9);
  if r != 0 { return r; }

  r = expect_reject("bare continuation 80", seq1(0x80), 10);
  if r != 0 { return r; }

  r = expect_reject("truncated E2 82", seq2(0xE2, 0x82), 11);
  if r != 0 { return r; }

  r = expect_reject("beyond max F4 90 80 80", seq4(0xF4, 0x90, 0x80, 0x80), 12);
  if r != 0 { return r; }

  r = expect_reject("reserved F5 80 80 80", seq4(0xF5, 0x80, 0x80, 0x80), 13);
  if r != 0 { return r; }

  // ---- validate/sequence counting on escaped literals ----
  if !utf8.utf8_validate("h\u{00E9}llo") { io.println("validate failed"); return 14; }
  if utf8.utf8_valid_sequences("h\u{00E9}llo") != 5 {
    io.println("valid_sequences wrong count");
    return 15;
  }

  io.println("kat_convert_utf8_decoder OK");
  return 0;
}
