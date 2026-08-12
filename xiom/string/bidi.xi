// XIOM - String: Bidi
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.bidi

// Depends on: none

// ============================================================================
// Unicode bidirectional text properties (UAX #9): bidi class, mirroring and
// mirrored-pair lookup. The class table is a compact representative subset:
// European/Arabic-Indic digits, European separators and terminaisons, Arabic
// letters, Hebrew letters, whitespace, format/BN controls, and combining marks
// (NSM). Everything else defaults to L. Coverage is documented inline.
//
// NOTE (BUG 20): the classifier walks its range table through a small
// recursive helper (one range per frame). A straight-line range-check chain
// gets SIMD-vectorized by the -O2 vectorizer into AVX-512 instructions that
// trap on CPUs without AVX-512 (0xC000001D).
// ============================================================================

/// Bidirectional class of `c` (two- or three-letter code per UAX #9): "L",
/// "R", "AL", "EN", "AN", "ES", "ET", "CS", "NSM", "WS", "B", "S", "BN",
/// "LRE", "LRO", "RLE", "RLO", "PDF", "ON". Unmapped codepoints report "L".
/// Params: c the character to classify.
/// Returns: the bidi class code.
/// Error case: none.
/// Complexity: O(1).
pub fn unicode_bidi_class(c: Char) -> Str {
  let code = _bidi_code(to_int_from_char(c));
  _bidi_name(code)
}

/// True when `c` has the Bidi_Mirrored property, i.e. it has a mirrored
/// counterpart used when the text direction flips (brackets, angle brackets,
/// curly braces, and a few quotes/guillemets). Unmapped codepoints are not
/// mirrored.
/// Params: c the character to test.
/// Returns: true when c is mirrored.
/// Error case: none.
/// Complexity: O(1).
pub fn unicode_mirrored(c: Char) -> Bool {
  let cp = to_int_from_char(c);
  _mirror_cp(cp) >= 0
}

/// Mirror image of `c`: the paired bracket/quote on the other side, or `c`
/// itself when `c` is not mirrored. E.g. '(' -> ')', ')' -> '(', '[' -> ']',
/// '{' -> '}', '<' -> '>', '«' -> '»', '‹' -> '›'.
/// Params: c the character to mirror.
/// Returns: the mirrored counterpart, or c itself.
/// Error case: none.
/// Complexity: O(1).
pub fn unicode_mirror_char(c: Char) -> Char {
  let cp = to_int_from_char(c);
  let m = _mirror_cp(cp);
  if m >= 0 {
    return to_char(m);
  };
  c
}

// Private helpers

// Bidi class codes: 1=L 2=R 3=AL 4=EN 5=AN 6=ES 7=ET 8=CS 9=NSM 10=WS
// 11=B 12=S 13=BN 14=LRE 15=LRO 16=RLE 17=RLO 18=PDF 19=ON

/// Bidi class of one codepoint; 1 (L) when unmapped.
fn _bidi_code(cp: Int) -> Int {
  _bd_r(cp, 0)
}

/// One range per recursion frame (see header note on BUG 20).
fn _bd_r(cp: Int, i: Int) -> Int {
  if i == 0 {
    if cp == 0x202A { return 14; };
  };
  if i == 1 {
    if cp == 0x202B { return 16; };
  };
  if i == 2 {
    if cp == 0x202C { return 18; };
  };
  if i == 3 {
    if cp == 0x202D { return 15; };
  };
  if i == 4 {
    if cp == 0x202E { return 17; };
  };
  if i == 5 {
    if cp >= 0x200B && cp <= 0x200D { return 13; };
  };
  if i == 6 {
    if cp >= 0x2060 && cp <= 0x206F { return 13; };
  };
  if i == 7 {
    if cp == 0xFEFF { return 13; };
  };
  if i == 8 {
    if cp >= 0x09 && cp <= 0x0D { return 10; };
  };
  if i == 9 {
    if cp >= 0x1C && cp <= 0x1E { return 12; };
  };
  if i == 10 {
    if cp == 0x20 { return 10; };
  };
  if i == 11 {
    if cp == 0x85 { return 12; };
  };
  if i == 12 {
    if cp == 0x1680 { return 10; };
  };
  if i == 13 {
    if cp >= 0x2000 && cp <= 0x200A { return 10; };
  };
  if i == 14 {
    if cp == 0x2028 { return 12; };
  };
  if i == 15 {
    if cp == 0x2029 { return 11; };
  };
  if i == 16 {
    if cp == 0x202F { return 10; };
  };
  if i == 17 {
    if cp == 0x205F { return 10; };
  };
  if i == 18 {
    if cp == 0x3000 { return 10; };
  };
  if i == 19 {
    if cp >= 0x0300 && cp <= 0x036F { return 9; };
  };
  if i == 20 {
    if cp >= 0x1AB0 && cp <= 0x1AFF { return 9; };
  };
  if i == 21 {
    if cp >= 0x1DC0 && cp <= 0x1DFF { return 9; };
  };
  if i == 22 {
    if cp >= 0x20D0 && cp <= 0x20FF { return 9; };
  };
  if i == 23 {
    if cp >= 0x30 && cp <= 0x39 { return 4; };
  };
  if i == 24 {
    if cp >= 0xB2 && cp <= 0xB9 { return 4; };
  };
  if i == 25 {
    if cp >= 0x2070 && cp <= 0x2079 { return 4; };
  };
  if i == 26 {
    if cp >= 0x2488 && cp <= 0x249B { return 4; };
  };
  if i == 27 {
    if cp >= 0x660 && cp <= 0x669 { return 5; };
  };
  if i == 28 {
    if cp >= 0x6F0 && cp <= 0x6F9 { return 5; };
  };
  if i == 29 {
    if cp >= 0x23 && cp <= 0x25 { return 7; };
  };
  if i == 30 {
    if cp >= 0xA2 && cp <= 0xA5 { return 7; };
  };
  if i == 31 {
    if cp >= 0x20A0 && cp <= 0x20CF { return 7; };
  };
  if i == 32 {
    if cp == 0x2B { return 6; };
  };
  if i == 33 {
    if cp == 0x2D { return 6; };
  };
  if i == 34 {
    if cp == 0x2C { return 8; };
  };
  if i == 35 {
    if cp >= 0x2E && cp <= 0x2F { return 8; };
  };
  if i == 36 {
    if cp == 0x3A { return 8; };
  };
  if i == 37 {
    if cp == 0xA0 { return 8; };
  };
  if i == 38 {
    if cp >= 0x591 && cp <= 0x5C7 { return 2; };
  };
  if i == 39 {
    if cp >= 0x5D0 && cp <= 0x5EA { return 2; };
  };
  if i == 40 {
    if cp >= 0x5EF && cp <= 0x5F4 { return 2; };
  };
  if i == 41 {
    if cp >= 0x7C0 && cp <= 0x7FF { return 2; };
  };
  if i == 42 {
    if cp >= 0xFB1D && cp <= 0xFB4F { return 2; };
  };
  if i == 43 {
    if cp >= 0x600 && cp <= 0x65F { return 3; };
  };
  if i == 44 {
    if cp >= 0x66A && cp <= 0x6EF { return 3; };
  };
  if i == 45 {
    if cp >= 0x6FA && cp <= 0x6FF { return 3; };
  };
  if i == 46 {
    if cp >= 0x750 && cp <= 0x77F { return 3; };
  };
  if i == 47 {
    if cp >= 0x8A0 && cp <= 0x8FF { return 3; };
  };
  if i == 48 {
    if cp >= 0xFB50 && cp <= 0xFDFF { return 3; };
  };
  if i == 49 {
    if cp >= 0xFE70 && cp <= 0xFEFE { return 3; };
  };
  if i < 49 {
    return _bd_r(cp, i + 1);
  };
  1
}


/// Bidi class name of a code.
fn _bidi_name(code: Int) -> Str {
  if code == 1 { return "L"; };
  if code == 2 { return "R"; };
  if code == 3 { return "AL"; };
  if code == 4 { return "EN"; };
  if code == 5 { return "AN"; };
  if code == 6 { return "ES"; };
  if code == 7 { return "ET"; };
  if code == 8 { return "CS"; };
  if code == 9 { return "NSM"; };
  if code == 10 { return "WS"; };
  if code == 11 { return "B"; };
  if code == 12 { return "S"; };
  if code == 13 { return "BN"; };
  if code == 14 { return "LRE"; };
  if code == 15 { return "LRO"; };
  if code == 16 { return "RLE"; };
  if code == 17 { return "RLO"; };
  if code == 18 { return "PDF"; };
  "L"
}

/// Mirrored counterpart of `cp`, -1 when not mirrored.
fn _mirror_cp(cp: Int) -> Int {
  if cp == 0x28 { return 0x29; };
  if cp == 0x29 { return 0x28; };
  if cp == 0x3C { return 0x3E; };
  if cp == 0x3E { return 0x3C; };
  if cp == 0x5B { return 0x5D; };
  if cp == 0x5D { return 0x5B; };
  if cp == 0x7B { return 0x7D; };
  if cp == 0x7D { return 0x7B; };
  if cp == 0xAB { return 0xBB; };
  if cp == 0xBB { return 0xAB; };
  if cp == 0x2039 { return 0x203A; };
  if cp == 0x203A { return 0x2039; };
  if cp == 0x2329 { return 0x232A; };
  if cp == 0x232A { return 0x2329; };
  if cp == 0x3008 { return 0x3009; };
  if cp == 0x3009 { return 0x3008; };
  if cp == 0x300A { return 0x300B; };
  if cp == 0x300B { return 0x300A; };
  if cp == 0x300C { return 0x300D; };
  if cp == 0x300D { return 0x300C; };
  if cp == 0x300E { return 0x300F; };
  if cp == 0x300F { return 0x300E; };
  if cp == 0x3010 { return 0x3011; };
  if cp == 0x3011 { return 0x3010; };
  if cp == 0xFF08 { return 0xFF09; };
  if cp == 0xFF09 { return 0xFF08; };
  -1
}