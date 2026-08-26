// kat_convert_utf8_encoder.xi -- UTF-8 ENCODER known-answer tests
// Every codepoint boundary class encodes to its exact byte sequence and
// round-trips through utf8_decode. Complements kat_convert_utf8_decoder
// (which pins the reject side).
module kat_convert_utf8_encoder
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

fn chr(cp: Int) -> Char {
  match convert.int_to_char(cp) {
    Some(c) => { return c; }
    None => { return '?'; }
  }
}

fn expect_bytes(tag: Str, cp: Int, want: Vec[UInt8], code: Int) -> Int {
  var got = utf8_encode(chr(cp));
  if got.len() != want.len() {
    io.println("utf8enc " + tag + ": len");
    return code;
  }
  var i = 0;
  while i < want.len() {
    if got[i] != want[i] {
      io.println("utf8enc " + tag + ": byte");
      return code;
    }
    i += 1;
  }
  return 0;
}

fn expect_roundtrip(tag: Str, cp: Int, code: Int) -> Int {
  var enc = utf8_encode(chr(cp));
  match utf8_decode(&enc) {
    Some(back) => {
      var got = convert.char_to_int(back);
      if got != cp {
        io.println("utf8rt " + tag + ": cp");
        return code;
      }
      return 0;
    }
    None => { io.println("utf8rt " + tag + ": rejected own output"); return code; }
  }
}

fn main() -> Int {
  // 1-byte forms
  var r = expect_bytes("0x41", 0x41, seq1(0x41), 1);
  if r != 0 { return r; }
  r = expect_bytes("0x7F", 0x7F, seq1(0x7F), 2);
  if r != 0 { return r; }

  // 2-byte forms (first continuation codepoint and boundary 0x7FF)
  r = expect_bytes("0x80", 0x80, seq2(0xC2, 0x80), 3);
  if r != 0 { return r; }
  r = expect_bytes("0x7FF", 0x7FF, seq2(0xDF, 0xBF), 4);
  if r != 0 { return r; }

  // 3-byte forms
  r = expect_bytes("0x800", 0x800, seq3(0xE0, 0xA0, 0x80), 5);
  if r != 0 { return r; }
  r = expect_bytes("0xFFFF", 0xFFFF, seq3(0xEF, 0xBF, 0xBF), 6);
  if r != 0 { return r; }

  // 4-byte forms
  r = expect_bytes("0x10000", 0x10000, seq4(0xF0, 0x90, 0x80, 0x80), 7);
  if r != 0 { return r; }
  r = expect_bytes("0x10FFFF", 0x10FFFF, seq4(0xF4, 0x8F, 0xBF, 0xBF), 8);
  if r != 0 { return r; }

  // round-trips across every boundary class
  // (no array literals in var position -- M33; explicit calls instead)
  r = expect_roundtrip("rt41", 0x41, 20);
  if r != 0 { return r; }
  r = expect_roundtrip("rt7F", 0x7F, 21);
  if r != 0 { return r; }
  r = expect_roundtrip("rt80", 0x80, 22);
  if r != 0 { return r; }
  r = expect_roundtrip("rt7FF", 0x7FF, 23);
  if r != 0 { return r; }
  r = expect_roundtrip("rt800", 0x800, 24);
  if r != 0 { return r; }
  r = expect_roundtrip("rtFFFF", 0xFFFF, 25);
  if r != 0 { return r; }
  r = expect_roundtrip("rt10000", 0x10000, 26);
  if r != 0 { return r; }
  r = expect_roundtrip("rt10FFFF", 0x10FFFF, 27);
  if r != 0 { return r; }

  io.println("OK");
  return 0;
}
