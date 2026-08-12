// XIOM - String: Script
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.script

// Depends on: none

// ============================================================================
// Unicode script property lookup (ISO 15924 codes). The table is a compact
// representative subset: Latin, Greek, Cyrillic, Hebrew, Arabic and the major
// South/Southeast Asian and CJK scripts, plus the special values Zyyy
// (Common), Zinh (Inherited), Zsym (Symbols) and Zzzz (unassigned). Coverage
// is documented inline.
//
// NOTE (BUG 20): the classifier walks its range table through a small
// recursive helper (one range per frame). A straight-line range-check chain
// gets SIMD-vectorized by the -O2 vectorizer into AVX-512 instructions that
// trap on CPUs without AVX-512 (0xC000001D).
// ============================================================================

/// ISO 15924 script code of `c`, e.g. "Latn" for 'A', "Hani" for a CJK
/// ideograph, "Zyyy" for common punctuation and digits. Unmapped codepoints
/// report "Zzzz" (unknown/unassigned).
/// Params: c the character to classify.
/// Returns: the four-letter ISO 15924 script code.
/// Error case: none.
/// Complexity: O(1).
pub fn unicode_script(c: Char) -> Str {
  let code = _script_code(to_int_from_char(c));
  _script_name(code)
}

/// Human-readable English script name for an ISO 15924 code, e.g. "Latn" ->
/// "Latin", "Zyyy" -> "Common". Unknown or unrecognised codes yield "Unknown".
/// Params: code the four-letter ISO 15924 code.
/// Returns: the long script name.
/// Error case: none; unknown codes map to "Unknown".
/// Complexity: O(1).
pub fn unicode_script_name(code: Str) -> Str {
  _code_to_name(code)
}

// Private helpers

// Script codes: 1=Latn 2=Grek 3=Cyrl 4=Hebr 5=Arab 6=Deva 7=Beng 8=Guru
// 9=Gujr 10=Orya 11=Taml 12=Telu 13=Knda 14=Mlym 15=Thai 16=Laoo 17=Tibt
// 18=Mymr 19=Hang 20=Ethi 21=Cher 22=Cans 23=Ogha 24=Runr 25=Khmr 26=Mong
// 27=Hani 28=Hira 29=Kana 30=Bopo 31=Zinh 32=Zyyy 33=Zsym 34=Zzzz 35=Yi

/// ISO 15924 code of one codepoint; 34 (Zzzz) when unmapped.
fn _script_code(cp: Int) -> Int {
  _scr_r(cp, 0)
}

/// One range per recursion frame (see header note on BUG 20).
fn _scr_r(cp: Int, i: Int) -> Int {
  if i == 0 {
    if cp >= 0x41 && cp <= 0x5A { return 1; };
  };
  if i == 1 {
    if cp >= 0x61 && cp <= 0x7A { return 1; };
  };
  if i == 2 {
    if cp >= 0 && cp <= 0x40 { return 32; };
  };
  if i == 3 {
    if cp >= 0x5B && cp <= 0x60 { return 32; };
  };
  if i == 4 {
    if cp >= 0x7B && cp <= 0x7F { return 32; };
  };
  if i == 5 {
    if cp >= 0x80 && cp <= 0x24F { return 1; };
  };
  if i == 6 {
    if cp >= 0x1E00 && cp <= 0x1EFF { return 1; };
  };
  if i == 7 {
    if cp >= 0x2C60 && cp <= 0x2C7F { return 1; };
  };
  if i == 8 {
    if cp >= 0xA720 && cp <= 0xA7FF { return 1; };
  };
  if i == 9 {
    if cp >= 0xAB30 && cp <= 0xAB6F { return 1; };
  };
  if i == 10 {
    if cp >= 0x370 && cp <= 0x3FF { return 2; };
  };
  if i == 11 {
    if cp >= 0x1F00 && cp <= 0x1FFF { return 2; };
  };
  if i == 12 {
    if cp >= 0x400 && cp <= 0x52F { return 3; };
  };
  if i == 13 {
    if cp >= 0x2DE0 && cp <= 0x2DFF { return 3; };
  };
  if i == 14 {
    if cp >= 0xA640 && cp <= 0xA69F { return 3; };
  };
  if i == 15 {
    if cp >= 0x590 && cp <= 0x5FF { return 4; };
  };
  if i == 16 {
    if cp >= 0xFB1D && cp <= 0xFB4F { return 4; };
  };
  if i == 17 {
    if cp >= 0x600 && cp <= 0x6FF { return 5; };
  };
  if i == 18 {
    if cp >= 0x750 && cp <= 0x77F { return 5; };
  };
  if i == 19 {
    if cp >= 0x870 && cp <= 0x89F { return 5; };
  };
  if i == 20 {
    if cp >= 0x8A0 && cp <= 0x8FF { return 5; };
  };
  if i == 21 {
    if cp >= 0xFB50 && cp <= 0xFDFF { return 5; };
  };
  if i == 22 {
    if cp >= 0xFE70 && cp <= 0xFEFF { return 5; };
  };
  if i == 23 {
    if cp >= 0x900 && cp <= 0x97F { return 6; };
  };
  if i == 24 {
    if cp >= 0xA8E0 && cp <= 0xA8FF { return 6; };
  };
  if i == 25 {
    if cp >= 0x980 && cp <= 0x9FF { return 7; };
  };
  if i == 26 {
    if cp >= 0xA00 && cp <= 0xA7F { return 8; };
  };
  if i == 27 {
    if cp >= 0xA80 && cp <= 0xAFF { return 9; };
  };
  if i == 28 {
    if cp >= 0xB00 && cp <= 0xB7F { return 10; };
  };
  if i == 29 {
    if cp >= 0xB80 && cp <= 0xBFF { return 11; };
  };
  if i == 30 {
    if cp >= 0x11FC0 && cp <= 0x11FFF { return 11; };
  };
  if i == 31 {
    if cp >= 0xC00 && cp <= 0xC7F { return 12; };
  };
  if i == 32 {
    if cp >= 0xC80 && cp <= 0xCFF { return 13; };
  };
  if i == 33 {
    if cp >= 0xD00 && cp <= 0xD7F { return 14; };
  };
  if i == 34 {
    if cp >= 0xE00 && cp <= 0xE7F { return 15; };
  };
  if i == 35 {
    if cp >= 0xE80 && cp <= 0xEFF { return 16; };
  };
  if i == 36 {
    if cp >= 0xF00 && cp <= 0xFFF { return 17; };
  };
  if i == 37 {
    if cp >= 0x1000 && cp <= 0x109F { return 18; };
  };
  if i == 38 {
    if cp >= 0xA9E0 && cp <= 0xA9FF { return 18; };
  };
  if i == 39 {
    if cp >= 0x1100 && cp <= 0x11FF { return 19; };
  };
  if i == 40 {
    if cp >= 0x3130 && cp <= 0x318F { return 19; };
  };
  if i == 41 {
    if cp >= 0xA960 && cp <= 0xA97F { return 19; };
  };
  if i == 42 {
    if cp >= 0xAC00 && cp <= 0xD7A3 { return 19; };
  };
  if i == 43 {
    if cp >= 0xD7B0 && cp <= 0xD7FF { return 19; };
  };
  if i == 44 {
    if cp >= 0x1200 && cp <= 0x139F { return 20; };
  };
  if i == 45 {
    if cp >= 0x2D80 && cp <= 0x2DDF { return 20; };
  };
  if i == 46 {
    if cp >= 0xAB00 && cp <= 0xAB2F { return 20; };
  };
  if i == 47 {
    if cp >= 0x13A0 && cp <= 0x13FF { return 21; };
  };
  if i == 48 {
    if cp >= 0xAB70 && cp <= 0xABBF { return 21; };
  };
  if i == 49 {
    if cp >= 0x1400 && cp <= 0x167F { return 22; };
  };
  if i == 50 {
    if cp >= 0x18B0 && cp <= 0x18FF { return 22; };
  };
  if i == 51 {
    if cp >= 0x1680 && cp <= 0x169F { return 23; };
  };
  if i == 52 {
    if cp >= 0x16A0 && cp <= 0x16FF { return 24; };
  };
  if i == 53 {
    if cp >= 0x1780 && cp <= 0x17FF { return 25; };
  };
  if i == 54 {
    if cp >= 0x19E0 && cp <= 0x19FF { return 25; };
  };
  if i == 55 {
    if cp >= 0x1800 && cp <= 0x18AF { return 26; };
  };
  if i == 56 {
    if cp >= 0x3400 && cp <= 0x4DBF { return 27; };
  };
  if i == 57 {
    if cp >= 0x4E00 && cp <= 0x9FFF { return 27; };
  };
  if i == 58 {
    if cp >= 0xF900 && cp <= 0xFAFF { return 27; };
  };
  if i == 59 {
    if cp >= 0x20000 && cp <= 0x2A6DF { return 27; };
  };
  if i == 60 {
    if cp >= 0x30000 && cp <= 0x323AF { return 27; };
  };
  if i == 61 {
    if cp >= 0x3040 && cp <= 0x309F { return 28; };
  };
  if i == 62 {
    if cp >= 0x1B000 && cp <= 0x1B11F { return 28; };
  };
  if i == 63 {
    if cp >= 0x30A0 && cp <= 0x30FF { return 29; };
  };
  if i == 64 {
    if cp >= 0x31F0 && cp <= 0x31FF { return 29; };
  };
  if i == 65 {
    if cp >= 0x3100 && cp <= 0x312F { return 30; };
  };
  if i == 66 {
    if cp >= 0x31A0 && cp <= 0x31BF { return 30; };
  };
  if i == 67 {
    if cp >= 0xA000 && cp <= 0xA48F { return 35; };
  };
  if i == 68 {
    if cp >= 0x0300 && cp <= 0x036F { return 31; };
  };
  if i == 69 {
    if cp >= 0x1AB0 && cp <= 0x1AFF { return 31; };
  };
  if i == 70 {
    if cp >= 0x1DC0 && cp <= 0x1DFF { return 31; };
  };
  if i == 71 {
    if cp >= 0x20D0 && cp <= 0x20FF { return 31; };
  };
  if i == 72 {
    if cp >= 0xFE00 && cp <= 0xFE0F { return 31; };
  };
  if i == 73 {
    if cp >= 0xFE20 && cp <= 0xFE2F { return 31; };
  };
  if i == 74 {
    if cp >= 0x1F000 && cp <= 0x1FAFF { return 33; };
  };
  if i == 75 {
    if cp >= 0x2000 && cp <= 0x206F { return 32; };
  };
  if i == 76 {
    if cp >= 0x2190 && cp <= 0x22FF { return 32; };
  };
  if i == 77 {
    if cp >= 0x2600 && cp <= 0x27BF { return 32; };
  };
  if i == 78 {
    if cp >= 0x2E00 && cp <= 0x2E7F { return 32; };
  };
  if i == 79 {
    if cp >= 0x3000 && cp <= 0x303F { return 32; };
  };
  if i == 80 {
    if cp >= 0xFE10 && cp <= 0xFE1F { return 32; };
  };
  if i == 81 {
    if cp >= 0xFE30 && cp <= 0xFE4F { return 32; };
  };
  if i == 82 {
    if cp >= 0xFE50 && cp <= 0xFE6F { return 32; };
  };
  if i == 83 {
    if cp >= 0xFF00 && cp <= 0xFFEF { return 32; };
  };
  if i < 83 {
    return _scr_r(cp, i + 1);
  };
  34
}


/// Long English name for a script code.
fn _script_name(code: Int) -> Str {
  if code == 1 { return "Latn"; };
  if code == 2 { return "Grek"; };
  if code == 3 { return "Cyrl"; };
  if code == 4 { return "Hebr"; };
  if code == 5 { return "Arab"; };
  if code == 6 { return "Deva"; };
  if code == 7 { return "Beng"; };
  if code == 8 { return "Guru"; };
  if code == 9 { return "Gujr"; };
  if code == 10 { return "Orya"; };
  if code == 11 { return "Taml"; };
  if code == 12 { return "Telu"; };
  if code == 13 { return "Knda"; };
  if code == 14 { return "Mlym"; };
  if code == 15 { return "Thai"; };
  if code == 16 { return "Laoo"; };
  if code == 17 { return "Tibt"; };
  if code == 18 { return "Mymr"; };
  if code == 19 { return "Hang"; };
  if code == 20 { return "Ethi"; };
  if code == 21 { return "Cher"; };
  if code == 22 { return "Cans"; };
  if code == 23 { return "Ogha"; };
  if code == 24 { return "Runr"; };
  if code == 25 { return "Khmr"; };
  if code == 26 { return "Mong"; };
  if code == 27 { return "Hani"; };
  if code == 28 { return "Hira"; };
  if code == 29 { return "Kana"; };
  if code == 30 { return "Bopo"; };
  if code == 31 { return "Zinh"; };
  if code == 32 { return "Zyyy"; };
  if code == 33 { return "Zsym"; };
  if code == 34 { return "Zzzz"; };
  if code == 35 { return "Yiii"; };
  "Zzzz"
}

/// Long English name for an ISO 15924 code string.
fn _code_to_name(code: Str) -> Str {
  if code == "Latn" { return "Latin"; };
  if code == "Grek" { return "Greek"; };
  if code == "Cyrl" { return "Cyrillic"; };
  if code == "Hebr" { return "Hebrew"; };
  if code == "Arab" { return "Arabic"; };
  if code == "Deva" { return "Devanagari"; };
  if code == "Beng" { return "Bengali"; };
  if code == "Guru" { return "Gurmukhi"; };
  if code == "Gujr" { return "Gujarati"; };
  if code == "Orya" { return "Oriya"; };
  if code == "Taml" { return "Tamil"; };
  if code == "Telu" { return "Telugu"; };
  if code == "Knda" { return "Kannada"; };
  if code == "Mlym" { return "Malayalam"; };
  if code == "Thai" { return "Thai"; };
  if code == "Laoo" { return "Lao"; };
  if code == "Tibt" { return "Tibetan"; };
  if code == "Mymr" { return "Myanmar"; };
  if code == "Hang" { return "Hangul"; };
  if code == "Ethi" { return "Ethiopic"; };
  if code == "Cher" { return "Cherokee"; };
  if code == "Cans" { return "Canadian_Aboriginal"; };
  if code == "Ogha" { return "Ogham"; };
  if code == "Runr" { return "Runic"; };
  if code == "Khmr" { return "Khmer"; };
  if code == "Mong" { return "Mongolian"; };
  if code == "Hani" { return "Han"; };
  if code == "Hira" { return "Hiragana"; };
  if code == "Kana" { return "Katakana"; };
  if code == "Bopo" { return "Bopomofo"; };
  if code == "Yiii" { return "Yi"; };
  if code == "Zyyy" { return "Common"; };
  if code == "Zinh" { return "Inherited"; };
  if code == "Zsym" { return "Symbols"; };
  if code == "Zzzz" { return "Unknown"; };
  "Unknown"
}