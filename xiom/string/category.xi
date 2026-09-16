// XIOM - String: Category
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.string.category

// Depends on: none

// ============================================================================
// Unicode general category and classification of characters. The table below
// is a compact representative subset: ASCII, Latin-1, Latin Extended-A/B,
// Greek, Cyrillic, CJK, Hangul, Kana, Arabic, Hebrew and Devanagari letters;
// ASCII/Arabic-Indic/Indic/Thai/Lao decimal digits; common punctuation,
// symbols, separators, combining marks, and control/format ranges. Unmapped
// codepoints report the general category "Cn" (Other, unassigned).
//
// NOTE (BUG 20): the classifier walks its range table through a small
// recursive helper (one range per frame). A straight-line range-check chain
// gets SIMD-vectorized by the -O2 vectorizer into AVX-512 instructions that
// trap on CPUs without AVX-512 (0xC000001D); recursion keeps each frame tiny
// so the vectorizer never sees a long classification chain.
// ============================================================================

/// Two-letter Unicode general category of `c`, e.g. "Lu", "Ll", "Nd", "Zs",
/// "Po". Unmapped codepoints report "Cn" (Other/unassigned).
/// Params: c the character to classify.
/// Returns: the two-letter general category code.
/// Error case: none.
/// Complexity: O(1).
pub fn unicode_general_category(c: Char) -> Str {
  _category(to_int_from_char(c))
}

/// True when `c` is a letter (categories Lu, Ll, Lt, Lm, Lo).
/// Params: c the character to test.
/// Returns: true when c is a letter.
/// Error case: none.
/// Complexity: O(1).
pub fn unicode_is_letter(c: Char) -> Bool {
  let cat = _category(to_int_from_char(c));
  _cat_is_letter(cat)
}

/// True when `c` is a decimal digit (category Nd).
/// Params: c the character to test.
/// Returns: true when c is a decimal digit.
/// Error case: none.
/// Complexity: O(1).
pub fn unicode_is_digit(c: Char) -> Bool {
  let cat = _category(to_int_from_char(c));
  cat == "Nd"
}

/// True when `c` is punctuation (categories Pc, Pd, Ps, Pe, Pi, Pf, Po).
/// Params: c the character to test.
/// Returns: true when c is punctuation.
/// Error case: none.
/// Complexity: O(1).
pub fn unicode_is_punct(c: Char) -> Bool {
  let cat = _category(to_int_from_char(c));
  _cat_is_punct(cat)
}

/// True when `c` is a symbol (categories Sm, Sc, Sk, So).
/// Params: c the character to test.
/// Returns: true when c is a symbol.
/// Error case: none.
/// Complexity: O(1).
pub fn unicode_is_symbol(c: Char) -> Bool {
  let cat = _category(to_int_from_char(c));
  _cat_is_symbol(cat)
}

/// True when `c` is a separator (categories Zs, Zl, Zp).
/// Params: c the character to test.
/// Returns: true when c is a separator.
/// Error case: none.
/// Complexity: O(1).
pub fn unicode_is_separator(c: Char) -> Bool {
  let cat = _category(to_int_from_char(c));
  _cat_is_separator(cat)
}

/// True when `c` is a control or format character, or otherwise falls in the
/// "Other" (C) group: Cc, Cf, Cs (surrogates), Co (private use) or Cn
/// (unassigned). The inverse of unicode_is_printable.
/// Params: c the character to test.
/// Returns: true when c is in category Cc/Cf/Cs/Co/Cn.
/// Error case: none.
/// Complexity: O(1).
pub fn unicode_is_control(c: Char) -> Bool {
  let cat = _category(to_int_from_char(c));
  _cat_is_control(cat)
}

/// True when `c` is printable, i.e. not a control/format character and not in
/// the "Other" (C) group. Letters, marks, numbers, punctuation, symbols and
/// separators are printable.
/// Params: c the character to test.
/// Returns: true when c is printable.
/// Error case: none.
/// Complexity: O(1).
pub fn unicode_is_printable(c: Char) -> Bool {
  let cat = _category(to_int_from_char(c));
  !_cat_is_control(cat)
}

// Private helpers

fn _cat_is_letter(cat: Str) -> Bool {
  if cat == "Lu" || cat == "Ll" || cat == "Lt" || cat == "Lm" || cat == "Lo" {
    return true;
  };
  false
}

fn _cat_is_punct(cat: Str) -> Bool {
  if cat == "Pc" || cat == "Pd" || cat == "Ps" || cat == "Pe" || cat == "Pi" || cat == "Pf" || cat == "Po" {
    return true;
  };
  false
}

fn _cat_is_symbol(cat: Str) -> Bool {
  if cat == "Sm" || cat == "Sc" || cat == "Sk" || cat == "So" {
    return true;
  };
  false
}

fn _cat_is_separator(cat: Str) -> Bool {
  if cat == "Zs" || cat == "Zl" || cat == "Zp" {
    return true;
  };
  false
}

fn _cat_is_control(cat: Str) -> Bool {
  if cat == "Cc" || cat == "Cf" || cat == "Cs" || cat == "Co" || cat == "Cn" {
    return true;
  };
  false
}

// General category codes: 1=Cc 2=Cf 3=Cn 4=Co 5=Cs 6=Ll 7=Lm 8=Lo 9=Lt
// 10=Lu 13=Mn 14=Nd 15=Nl 16=No 17=Pc 18=Pd 19=Pe 20=Pf 21=Pi 22=Po
// 23=Ps 24=Sc 25=Sk 26=Sm 27=So 28=Zl 29=Zp 30=Zs

/// General category code of one codepoint; 3 (Cn) when unmapped.
fn _cat_code(cp: Int) -> Int {
  // Latin Extended pair ranges: uppercase at even, lowercase at odd codepoints.
  if cp >= 0x100 && cp <= 0x137 {
    if (cp & 1) == 0 { return 10; } else { return 6; };
  };
  if cp >= 0x139 && cp <= 0x148 {
    if (cp & 1) == 0 { return 10; } else { return 6; };
  };
  if cp >= 0x14A && cp <= 0x177 {
    if (cp & 1) == 0 { return 10; } else { return 6; };
  };
  if cp >= 0x179 && cp <= 0x17D {
    if (cp & 1) == 0 { return 10; } else { return 6; };
  };
  if cp >= 0x1E00 && cp <= 0x1EFF {
    if (cp & 1) == 0 { return 10; } else { return 6; };
  };
  if cp >= 0x490 && cp <= 0x4CF {
    if (cp & 1) == 0 { return 10; } else { return 6; };
  };
  _cat_r(cp, 0)
}

/// One range per recursion frame (see header note on BUG 20).
fn _cat_r(cp: Int, i: Int) -> Int {
  if i == 0 {
    if cp >= 0 && cp <= 0x1F { return 1; };
  };
  if i == 1 {
    if cp >= 0x7F && cp <= 0x9F { return 1; };
  };
  if i == 2 {
    if cp == 0xAD { return 2; };
  };
  if i == 3 {
    if cp >= 0x200B && cp <= 0x200F { return 2; };
  };
  if i == 4 {
    if cp >= 0x202A && cp <= 0x202E { return 2; };
  };
  if i == 5 {
    if cp >= 0x2060 && cp <= 0x206F { return 2; };
  };
  if i == 6 {
    if cp == 0xFEFF { return 2; };
  };
  if i == 7 {
    if cp >= 0xD800 && cp <= 0xDFFF { return 5; };
  };
  if i == 8 {
    if cp >= 0xE000 && cp <= 0xF8FF { return 4; };
  };
  if i == 9 {
    if cp >= 0xF0000 && cp <= 0xFFFFD { return 4; };
  };
  if i == 10 {
    if cp >= 0x100000 && cp <= 0x10FFFD { return 4; };
  };
  if i == 11 {
    if cp >= 0x0300 && cp <= 0x036F { return 13; };
  };
  if i == 12 {
    if cp >= 0x1AB0 && cp <= 0x1AFF { return 13; };
  };
  if i == 13 {
    if cp >= 0x1DC0 && cp <= 0x1DFF { return 13; };
  };
  if i == 14 {
    if cp >= 0x20D0 && cp <= 0x20FF { return 13; };
  };
  if i == 15 {
    if cp >= 0xFE20 && cp <= 0xFE2F { return 13; };
  };
  if i == 16 {
    if cp == 0x20 || cp == 0xA0 { return 30; };
  };
  if i == 17 {
    if cp == 0x1680 { return 30; };
  };
  if i == 18 {
    if cp >= 0x2000 && cp <= 0x200A { return 30; };
  };
  if i == 19 {
    if cp == 0x202F || cp == 0x205F || cp == 0x3000 { return 30; };
  };
  if i == 20 {
    if cp == 0x2028 { return 28; };
  };
  if i == 21 {
    if cp == 0x2029 { return 29; };
  };
  if i == 22 {
    if cp >= 0x30 && cp <= 0x39 { return 14; };
  };
  if i == 23 {
    if cp >= 0x660 && cp <= 0x669 { return 14; };
  };
  if i == 24 {
    if cp >= 0x6F0 && cp <= 0x6F9 { return 14; };
  };
  if i == 25 {
    if cp >= 0x966 && cp <= 0x96F { return 14; };
  };
  if i == 26 {
    if cp >= 0x09E6 && cp <= 0x09EF { return 14; };
  };
  if i == 27 {
    if cp >= 0x0BE6 && cp <= 0x0BEF { return 14; };
  };
  if i == 28 {
    if cp >= 0x0E50 && cp <= 0x0E59 { return 14; };
  };
  if i == 29 {
    if cp >= 0x0ED0 && cp <= 0x0ED9 { return 14; };
  };
  if i == 30 {
    if cp >= 0x2160 && cp <= 0x2182 { return 15; };
  };
  if i == 31 {
    if cp >= 0x2185 && cp <= 0x2188 { return 15; };
  };
  if i == 32 {
    if cp == 0xB2 || cp == 0xB3 || cp == 0xB9 { return 16; };
  };
  if i == 33 {
    if cp >= 0xBC && cp <= 0xBE { return 16; };
  };
  if i == 34 {
    if cp == 0x2070 { return 16; };
  };
  if i == 35 {
    if cp >= 0x2074 && cp <= 0x2079 { return 16; };
  };
  if i == 36 {
    if cp >= 0x2080 && cp <= 0x2089 { return 16; };
  };
  if i == 37 {
    if cp >= 0x2150 && cp <= 0x215F { return 16; };
  };
  if i == 38 {
    if cp >= 0x2460 && cp <= 0x24FF { return 16; };
  };
  if i == 39 {
    if cp >= 0x41 && cp <= 0x5A { return 10; };
  };
  if i == 40 {
    if cp >= 0xC0 && cp <= 0xD6 { return 10; };
  };
  if i == 41 {
    if cp >= 0xD8 && cp <= 0xDE { return 10; };
  };
  if i == 42 {
    if cp >= 0x391 && cp <= 0x3A1 { return 10; };
  };
  if i == 43 {
    if cp >= 0x3A3 && cp <= 0x3AB { return 10; };
  };
  if i == 44 {
    if cp >= 0x400 && cp <= 0x42F { return 10; };
  };
  if i == 45 {
    if cp >= 0x531 && cp <= 0x556 { return 10; };
  };
  if i == 46 {
    if cp == 0x386 { return 10; };
  };
  if i == 47 {
    if cp >= 0x388 && cp <= 0x38A { return 10; };
  };
  if i == 48 {
    if cp == 0x38C { return 10; };
  };
  if i == 49 {
    if cp >= 0x38E && cp <= 0x38F { return 10; };
  };
  if i == 50 {
    if cp == 0x1C5 || cp == 0x1C8 || cp == 0x1CB || cp == 0x1F2 { return 9; };
  };
  if i == 51 {
    if cp >= 0x1F88 && cp <= 0x1F8F { return 9; };
  };
  if i == 52 {
    if cp >= 0x1F98 && cp <= 0x1F9F { return 9; };
  };
  if i == 53 {
    if cp >= 0x1FA8 && cp <= 0x1FAF { return 9; };
  };
  if i == 54 {
    if cp == 0x1FBC || cp == 0x1FCC || cp == 0x1FFC { return 9; };
  };
  if i == 55 {
    if cp >= 0x61 && cp <= 0x7A { return 6; };
  };
  if i == 56 {
    if cp == 0xB5 || cp == 0xDF { return 6; };
  };
  if i == 57 {
    if cp >= 0xE0 && cp <= 0xF6 { return 6; };
  };
  if i == 58 {
    if cp >= 0xF8 && cp <= 0xFF { return 6; };
  };
  if i == 59 {
    if cp >= 0x3AC && cp <= 0x3CE { return 6; };
  };
  if i == 60 {
    if cp >= 0x430 && cp <= 0x45F { return 6; };
  };
  if i == 61 {
    if cp >= 0x561 && cp <= 0x587 { return 6; };
  };
  if i == 62 {
    if cp >= 0x2B0 && cp <= 0x2C1 { return 7; };
  };
  if i == 63 {
    if cp >= 0x2C6 && cp <= 0x2D1 { return 7; };
  };
  if i == 64 {
    if cp >= 0x2E0 && cp <= 0x2E4 { return 7; };
  };
  if i == 65 {
    if cp == 0x2EC || cp == 0x2EE { return 7; };
  };
  if i == 66 {
    if cp >= 0x4E00 && cp <= 0x9FFF { return 8; };
  };
  if i == 67 {
    if cp >= 0x3400 && cp <= 0x4DBF { return 8; };
  };
  if i == 68 {
    if cp >= 0xF900 && cp <= 0xFAFF { return 8; };
  };
  if i == 69 {
    if cp >= 0x20000 && cp <= 0x2A6DF { return 8; };
  };
  if i == 70 {
    if cp >= 0xAC00 && cp <= 0xD7A3 { return 8; };
  };
  if i == 71 {
    if cp >= 0x1100 && cp <= 0x11FF { return 8; };
  };
  if i == 72 {
    if cp >= 0x3130 && cp <= 0x318F { return 8; };
  };
  if i == 73 {
    if cp >= 0x3040 && cp <= 0x309F { return 8; };
  };
  if i == 74 {
    if cp >= 0x30A0 && cp <= 0x30FF { return 8; };
  };
  if i == 75 {
    if cp >= 0x31F0 && cp <= 0x31FF { return 8; };
  };
  if i == 76 {
    if cp >= 0xA000 && cp <= 0xA48F { return 8; };
  };
  if i == 77 {
    if cp >= 0x0620 && cp <= 0x063F { return 8; };
  };
  if i == 78 {
    if cp >= 0x0641 && cp <= 0x064A { return 8; };
  };
  if i == 79 {
    if cp >= 0x0671 && cp <= 0x06D3 { return 8; };
  };
  if i == 80 {
    if cp >= 0x05D0 && cp <= 0x05EA { return 8; };
  };
  if i == 81 {
    if cp >= 0x05EF && cp <= 0x05F2 { return 8; };
  };
  if i == 82 {
    if cp >= 0x0904 && cp <= 0x0939 { return 8; };
  };
  if i == 83 {
    if cp >= 0x0958 && cp <= 0x0961 { return 8; };
  };
  if i == 84 {
    if cp == 0x5F { return 17; };
  };
  if i == 85 {
    if cp == 0x203F || cp == 0x2040 || cp == 0x2054 { return 17; };
  };
  if i == 86 {
    if cp == 0xFE33 || cp == 0xFE34 { return 17; };
  };
  if i == 87 {
    if cp >= 0xFE4D && cp <= 0xFE4F { return 17; };
  };
  if i == 88 {
    if cp == 0xFF3F { return 17; };
  };
  if i == 89 {
    if cp == 0x2D { return 18; };
  };
  if i == 90 {
    if cp >= 0x2010 && cp <= 0x2015 { return 18; };
  };
  if i == 91 {
    if cp == 0x2E17 { return 18; };
  };
  if i == 92 {
    if cp == 0x301C || cp == 0x3030 || cp == 0x30A0 { return 18; };
  };
  if i == 93 {
    if cp == 0xFE31 || cp == 0xFE32 || cp == 0xFE58 || cp == 0xFE63 { return 18; };
  };
  if i == 94 {
    if cp == 0xFF0D { return 18; };
  };
  if i == 95 {
    if cp == 0xAB || cp == 0x2018 || cp == 0x201B || cp == 0x201C || cp == 0x201F || cp == 0x2039 { return 21; };
  };
  if i == 96 {
    if cp == 0xBB || cp == 0x2019 || cp == 0x201D || cp == 0x203A { return 20; };
  };
  if i == 97 {
    if cp == 0x28 || cp == 0x5B || cp == 0x7B { return 23; };
  };
  if i == 98 {
    if cp == 0x2045 { return 23; };
  };
  if i == 99 {
    if cp == 0x2329 { return 23; };
  };
  if i == 100 {
    if cp == 0x3008 || cp == 0x300A || cp == 0x300C || cp == 0x300E || cp == 0x3010 { return 23; };
  };
  if i == 101 {
    if cp == 0x3014 || cp == 0x3016 || cp == 0x3018 || cp == 0x301A { return 23; };
  };
  if i == 102 {
    if cp == 0x301D { return 23; };
  };
  if i == 103 {
    if cp == 0xFD3E { return 23; };
  };
  if i == 104 {
    if cp == 0xFE17 { return 23; };
  };
  if i == 105 {
    if cp == 0xFE59 || cp == 0xFE5B || cp == 0xFE5D { return 23; };
  };
  if i == 106 {
    if cp == 0xFF08 || cp == 0xFF3B || cp == 0xFF5B || cp == 0xFF62 { return 23; };
  };
  if i == 107 {
    if cp == 0x29 || cp == 0x5D || cp == 0x7D { return 19; };
  };
  if i == 108 {
    if cp == 0x2046 { return 19; };
  };
  if i == 109 {
    if cp == 0x232A { return 19; };
  };
  if i == 110 {
    if cp == 0x3009 || cp == 0x300B || cp == 0x300D || cp == 0x300F || cp == 0x3011 { return 19; };
  };
  if i == 111 {
    if cp == 0x3015 || cp == 0x3017 || cp == 0x3019 || cp == 0x301B { return 19; };
  };
  if i == 112 {
    if cp == 0x301E || cp == 0x301F { return 19; };
  };
  if i == 113 {
    if cp == 0xFD3F { return 19; };
  };
  if i == 114 {
    if cp == 0xFE18 { return 19; };
  };
  if i == 115 {
    if cp == 0xFE5A || cp == 0xFE5C || cp == 0xFE5E { return 19; };
  };
  if i == 116 {
    if cp == 0xFF09 || cp == 0xFF3D || cp == 0xFF5D || cp == 0xFF63 { return 19; };
  };
  if i == 117 {
    if cp == 0x21 || cp == 0x22 || cp == 0x23 || cp == 0x25 || cp == 0x26 || cp == 0x27 || cp == 0x2A { return 22; };
  };
  if i == 118 {
    if cp == 0x2C || cp == 0x2E || cp == 0x2F || cp == 0x3A || cp == 0x3B || cp == 0x3F || cp == 0x40 || cp == 0x5C { return 22; };
  };
  if i == 119 {
    if cp == 0xA1 || cp == 0xA7 || cp == 0xB6 || cp == 0xB7 || cp == 0xBF { return 22; };
  };
  if i == 120 {
    if cp >= 0x2016 && cp <= 0x2017 { return 22; };
  };
  if i == 121 {
    if cp >= 0x2020 && cp <= 0x2027 { return 22; };
  };
  if i == 122 {
    if cp >= 0x2030 && cp <= 0x2038 { return 22; };
  };
  if i == 123 {
    if cp >= 0x203B && cp <= 0x203E { return 22; };
  };
  if i == 124 {
    if cp >= 0x2041 && cp <= 0x2043 { return 22; };
  };
  if i == 125 {
    if cp >= 0x2047 && cp <= 0x2051 { return 22; };
  };
  if i == 126 {
    if cp == 0x2053 { return 22; };
  };
  if i == 127 {
    if cp >= 0x2055 && cp <= 0x205E { return 22; };
  };
  if i == 128 {
    if cp >= 0x3001 && cp <= 0x3003 { return 22; };
  };
  if i == 129 {
    if cp == 0x303D { return 22; };
  };
  if i == 130 {
    if cp == 0x30FB { return 22; };
  };
  if i == 131 {
    if cp >= 0xFE10 && cp <= 0xFE16 { return 22; };
  };
  if i == 132 {
    if cp == 0xFE19 { return 22; };
  };
  if i == 133 {
    if cp == 0xFE30 || cp == 0xFE45 || cp == 0xFE46 { return 22; };
  };
  if i == 134 {
    if cp >= 0xFE49 && cp <= 0xFE4C { return 22; };
  };
  if i == 135 {
    if cp >= 0xFE50 && cp <= 0xFE52 { return 22; };
  };
  if i == 136 {
    if cp >= 0xFE54 && cp <= 0xFE57 { return 22; };
  };
  if i == 137 {
    if cp >= 0xFE5F && cp <= 0xFE61 { return 22; };
  };
  if i == 138 {
    if cp == 0xFE68 || cp == 0xFE6A || cp == 0xFE6B { return 22; };
  };
  if i == 139 {
    if cp == 0xFF01 || cp == 0xFF02 || cp == 0xFF07 || cp == 0xFF0A || cp == 0xFF0C { return 22; };
  };
  if i == 140 {
    if cp == 0xFF0E || cp == 0xFF0F || cp == 0xFF1A || cp == 0xFF1B || cp == 0xFF1F { return 22; };
  };
  if i == 141 {
    if cp == 0xFF40 || cp == 0xFF5C || cp == 0xFF5E || cp == 0xFF65 { return 22; };
  };
  if i == 142 {
    if cp == 0x2B || cp == 0x3C || cp == 0x3D || cp == 0x3E || cp == 0x7C || cp == 0x7E { return 26; };
  };
  if i == 143 {
    if cp == 0xAC || cp == 0xB1 || cp == 0xD7 || cp == 0xF7 { return 26; };
  };
  if i == 144 {
    if cp == 0x2044 || cp == 0x2052 { return 26; };
  };
  if i == 145 {
    if cp >= 0x2190 && cp <= 0x21FF { return 26; };
  };
  if i == 146 {
    if cp >= 0x2200 && cp <= 0x22FF { return 26; };
  };
  if i == 147 {
    if cp >= 0x2308 && cp <= 0x230B { return 26; };
  };
  if i == 148 {
    if cp == 0x2320 || cp == 0x2321 { return 26; };
  };
  if i == 149 {
    if cp >= 0x27C0 && cp <= 0x27EF { return 26; };
  };
  if i == 150 {
    if cp >= 0x2900 && cp <= 0x29FF { return 26; };
  };
  if i == 151 {
    if cp >= 0x2A00 && cp <= 0x2AFF { return 26; };
  };
  if i == 152 {
    if cp == 0x24 || cp == 0xA2 || cp == 0xA3 || cp == 0xA4 || cp == 0xA5 { return 24; };
  };
  if i == 153 {
    if cp >= 0x20A0 && cp <= 0x20CF { return 24; };
  };
  if i == 154 {
    if cp == 0xFFE0 || cp == 0xFFE1 || cp == 0xFFE5 || cp == 0xFFE6 { return 24; };
  };
  if i == 155 {
    if cp == 0x0E3F || cp == 0x17DB || cp == 0x060B { return 24; };
  };
  if i == 156 {
    if cp == 0x5E || cp == 0x60 || cp == 0xA8 || cp == 0xAF || cp == 0xB4 || cp == 0xB8 { return 25; };
  };
  if i == 157 {
    if cp >= 0x2C2 && cp <= 0x2C5 { return 25; };
  };
  if i == 158 {
    if cp >= 0x2D2 && cp <= 0x2DF { return 25; };
  };
  if i == 159 {
    if cp >= 0x2E5 && cp <= 0x2EB { return 25; };
  };
  if i == 160 {
    if cp == 0x2ED { return 25; };
  };
  if i == 161 {
    if cp >= 0x2EF && cp <= 0x2FF { return 25; };
  };
  if i == 162 {
    if cp == 0x0374 || cp == 0x0375 || cp == 0x0384 || cp == 0x0385 { return 25; };
  };
  if i == 163 {
    if cp == 0x1FBD || cp == 0x1FBF || cp == 0x1FC0 || cp == 0x1FC1 { return 25; };
  };
  if i == 164 {
    if cp >= 0x1FCD && cp <= 0x1FCF { return 25; };
  };
  if i == 165 {
    if cp >= 0x1FDD && cp <= 0x1FDF { return 25; };
  };
  if i == 166 {
    if cp >= 0x1FED && cp <= 0x1FEF { return 25; };
  };
  if i == 167 {
    if cp == 0x1FFD || cp == 0x1FFE { return 25; };
  };
  if i == 168 {
    if cp == 0x309B || cp == 0x309C { return 25; };
  };
  if i == 169 {
    if cp >= 0xA700 && cp <= 0xA716 { return 25; };
  };
  if i == 170 {
    if cp == 0xFF3E || cp == 0xFF40 || cp == 0xFFE3 { return 25; };
  };
  if i == 171 {
    if cp == 0xA6 || cp == 0xA9 || cp == 0xAE || cp == 0xB0 { return 27; };
  };
  if i == 172 {
    if cp >= 0x2300 && cp <= 0x2307 { return 27; };
  };
  if i == 173 {
    if cp >= 0x230C && cp <= 0x231F { return 27; };
  };
  if i == 174 {
    if cp >= 0x2322 && cp <= 0x2328 { return 27; };
  };
  if i == 175 {
    if cp >= 0x232B && cp <= 0x237F { return 27; };
  };
  if i == 176 {
    if cp >= 0x23E9 && cp <= 0x23FF { return 27; };
  };
  if i == 177 {
    if cp >= 0x25A0 && cp <= 0x25FF { return 27; };
  };
  if i == 178 {
    if cp >= 0x2600 && cp <= 0x26FF { return 27; };
  };
  if i == 179 {
    if cp >= 0x2700 && cp <= 0x27BF { return 27; };
  };
  if i == 180 {
    if cp >= 0x2B00 && cp <= 0x2BFF { return 27; };
  };
  if i == 181 {
    if cp >= 0x1F000 && cp <= 0x1FAFF { return 27; };
  };
  if i < 181 {
    return _cat_r(cp, i + 1);
  };
  3
}


/// Two-letter category name of a code.
fn _cat_name(code: Int) -> Str {
  if code == 1 { return "Cc"; };
  if code == 2 { return "Cf"; };
  if code == 3 { return "Cn"; };
  if code == 4 { return "Co"; };
  if code == 5 { return "Cs"; };
  if code == 6 { return "Ll"; };
  if code == 7 { return "Lm"; };
  if code == 8 { return "Lo"; };
  if code == 9 { return "Lt"; };
  if code == 10 { return "Lu"; };
  if code == 13 { return "Mn"; };
  if code == 14 { return "Nd"; };
  if code == 15 { return "Nl"; };
  if code == 16 { return "No"; };
  if code == 17 { return "Pc"; };
  if code == 18 { return "Pd"; };
  if code == 19 { return "Pe"; };
  if code == 20 { return "Pf"; };
  if code == 21 { return "Pi"; };
  if code == 22 { return "Po"; };
  if code == 23 { return "Ps"; };
  if code == 24 { return "Sc"; };
  if code == 25 { return "Sk"; };
  if code == 26 { return "Sm"; };
  if code == 27 { return "So"; };
  if code == 28 { return "Zl"; };
  if code == 29 { return "Zp"; };
  if code == 30 { return "Zs"; };
  "Cn"
}

/// General category of one codepoint.
fn _category(cp: Int) -> Str {
  let code = _cat_code(cp);
  _cat_name(code)
}