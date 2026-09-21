// XIOM - String: Block
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.block

// Depends on: none

// ============================================================================
// Unicode block property lookup. NOTE: current implementation lives in
// string.unicode stub - move the functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;

extern "C" {
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

/// Returns the Unicode block name for a code point, or "Undefined" when the
/// code point does not fall inside a known block. The table covers the most
/// common blocks (ASCII, Latin, CJK, Greek/Cyrillic, symbols, emoji, ...).
/// Complexity: O(number of table entries).
fn _block_name(cp: Int) -> Str {
  if cp >= 0x0000 && cp <= 0x007F { return "Basic Latin"; };
  if cp >= 0x0080 && cp <= 0x00FF { return "Latin-1 Supplement"; };
  if cp >= 0x0100 && cp <= 0x017F { return "Latin Extended-A"; };
  if cp >= 0x0180 && cp <= 0x024F { return "Latin Extended-B"; };
  if cp >= 0x0250 && cp <= 0x02AF { return "IPA Extensions"; };
  if cp >= 0x02B0 && cp <= 0x02FF { return "Spacing Modifier Letters"; };
  if cp >= 0x0300 && cp <= 0x036F { return "Combining Diacritical Marks"; };
  if cp >= 0x0370 && cp <= 0x03FF { return "Greek and Coptic"; };
  if cp >= 0x0400 && cp <= 0x04FF { return "Cyrillic"; };
  if cp >= 0x0500 && cp <= 0x052F { return "Cyrillic Supplement"; };
  if cp >= 0x0530 && cp <= 0x058F { return "Armenian"; };
  if cp >= 0x0590 && cp <= 0x05FF { return "Hebrew"; };
  if cp >= 0x0600 && cp <= 0x06FF { return "Arabic"; };
  if cp >= 0x0700 && cp <= 0x074F { return "Syriac"; };
  if cp >= 0x0750 && cp <= 0x077F { return "Arabic Supplement"; };
  if cp >= 0x0780 && cp <= 0x07BF { return "Thaana"; };
  if cp >= 0x0900 && cp <= 0x097F { return "Devanagari"; };
  if cp >= 0x0980 && cp <= 0x09FF { return "Bengali"; };
  if cp >= 0x0A00 && cp <= 0x0A7F { return "Gurmukhi"; };
  if cp >= 0x0A80 && cp <= 0x0AFF { return "Gujarati"; };
  if cp >= 0x0B00 && cp <= 0x0B7F { return "Oriya"; };
  if cp >= 0x0B80 && cp <= 0x0BFF { return "Tamil"; };
  if cp >= 0x0C00 && cp <= 0x0C7F { return "Telugu"; };
  if cp >= 0x0C80 && cp <= 0x0CFF { return "Kannada"; };
  if cp >= 0x0D00 && cp <= 0x0D7F { return "Malayalam"; };
  if cp >= 0x0E00 && cp <= 0x0E7F { return "Thai"; };
  if cp >= 0x0E80 && cp <= 0x0EFF { return "Lao"; };
  if cp >= 0x0F00 && cp <= 0x0FFF { return "Tibetan"; };
  if cp >= 0x1000 && cp <= 0x109F { return "Myanmar"; };
  if cp >= 0x1100 && cp <= 0x11FF { return "Hangul Jamo"; };
  if cp >= 0x1200 && cp <= 0x137F { return "Ethiopic"; };
  if cp >= 0x13A0 && cp <= 0x13FF { return "Cherokee"; };
  if cp >= 0x1400 && cp <= 0x167F { return "Unified Canadian Aboriginal Syllabics"; };
  if cp >= 0x1680 && cp <= 0x169F { return "Ogham"; };
  if cp >= 0x16A0 && cp <= 0x16FF { return "Runic"; };
  if cp >= 0x1700 && cp <= 0x171F { return "Tagalog"; };
  if cp >= 0x1720 && cp <= 0x173F { return "Hanunoo"; };
  if cp >= 0x1740 && cp <= 0x175F { return "Buhid"; };
  if cp >= 0x1760 && cp <= 0x177F { return "Tagbanwa"; };
  if cp >= 0x1780 && cp <= 0x17FF { return "Khmer"; };
  if cp >= 0x1800 && cp <= 0x18AF { return "Mongolian"; };
  if cp >= 0x1900 && cp <= 0x194F { return "Limbu"; };
  if cp >= 0x1E00 && cp <= 0x1EFF { return "Latin Extended Additional"; };
  if cp >= 0x1F00 && cp <= 0x1FFF { return "Greek Extended"; };
  if cp >= 0x2000 && cp <= 0x206F { return "General Punctuation"; };
  if cp >= 0x2070 && cp <= 0x209F { return "Superscripts and Subscripts"; };
  if cp >= 0x20A0 && cp <= 0x20CF { return "Currency Symbols"; };
  if cp >= 0x20D0 && cp <= 0x20FF { return "Combining Diacritical Marks for Symbols"; };
  if cp >= 0x2100 && cp <= 0x214F { return "Letterlike Symbols"; };
  if cp >= 0x2150 && cp <= 0x218F { return "Number Forms"; };
  if cp >= 0x2190 && cp <= 0x21FF { return "Arrows"; };
  if cp >= 0x2200 && cp <= 0x22FF { return "Mathematical Operators"; };
  if cp >= 0x2300 && cp <= 0x23FF { return "Miscellaneous Technical"; };
  if cp >= 0x2400 && cp <= 0x243F { return "Control Pictures"; };
  if cp >= 0x2440 && cp <= 0x245F { return "Optical Character Recognition"; };
  if cp >= 0x2460 && cp <= 0x24FF { return "Enclosed Alphanumerics"; };
  if cp >= 0x2500 && cp <= 0x257F { return "Box Drawing"; };
  if cp >= 0x2580 && cp <= 0x259F { return "Block Elements"; };
  if cp >= 0x25A0 && cp <= 0x25FF { return "Geometric Shapes"; };
  if cp >= 0x2600 && cp <= 0x26FF { return "Miscellaneous Symbols"; };
  if cp >= 0x2700 && cp <= 0x27BF { return "Dingbats"; };
  if cp >= 0x2800 && cp <= 0x28FF { return "Braille Patterns"; };
  if cp >= 0x2E80 && cp <= 0x2EFF { return "CJK Radicals Supplement"; };
  if cp >= 0x2F00 && cp <= 0x2FDF { return "Kangxi Radicals"; };
  if cp >= 0x3000 && cp <= 0x303F { return "CJK Symbols and Punctuation"; };
  if cp >= 0x3040 && cp <= 0x309F { return "Hiragana"; };
  if cp >= 0x30A0 && cp <= 0x30FF { return "Katakana"; };
  if cp >= 0x3100 && cp <= 0x312F { return "Bopomofo"; };
  if cp >= 0x3130 && cp <= 0x318F { return "Hangul Compatibility Jamo"; };
  if cp >= 0x3190 && cp <= 0x319F { return "Kanbun"; };
  if cp >= 0x3200 && cp <= 0x32FF { return "Enclosed CJK Letters and Months"; };
  if cp >= 0x3300 && cp <= 0x33FF { return "CJK Compatibility"; };
  if cp >= 0x3400 && cp <= 0x4DBF { return "CJK Unified Ideographs Extension A"; };
  if cp >= 0x4E00 && cp <= 0x9FFF { return "CJK Unified Ideographs"; };
  if cp >= 0xA000 && cp <= 0xA48F { return "Yi Syllables"; };
  if cp >= 0xAC00 && cp <= 0xD7AF { return "Hangul Syllables"; };
  if cp >= 0xD800 && cp <= 0xDFFF { return "Surrogates"; };
  if cp >= 0xE000 && cp <= 0xF8FF { return "Private Use Area"; };
  if cp >= 0xF900 && cp <= 0xFAFF { return "CJK Compatibility Ideographs"; };
  if cp >= 0xFB00 && cp <= 0xFB4F { return "Alphabetic Presentation Forms"; };
  if cp >= 0xFB50 && cp <= 0xFDFF { return "Arabic Presentation Forms-A"; };
  if cp >= 0xFE00 && cp <= 0xFE0F { return "Variation Selectors"; };
  if cp >= 0xFE20 && cp <= 0xFE2F { return "Combining Half Marks"; };
  if cp >= 0xFE30 && cp <= 0xFE4F { return "CJK Compatibility Forms"; };
  if cp >= 0xFE50 && cp <= 0xFE6F { return "Small Form Variants"; };
  if cp >= 0xFE70 && cp <= 0xFEFF { return "Arabic Presentation Forms-B"; };
  if cp >= 0xFF00 && cp <= 0xFFEF { return "Halfwidth and Fullwidth Forms"; };
  if cp >= 0xFFF0 && cp <= 0xFFFF { return "Specials"; };
  if cp >= 0x1D300 && cp <= 0x1D35F { return "Tai Xuan Jing Symbols"; };
  if cp >= 0x1F300 && cp <= 0x1F5FF { return "Miscellaneous Symbols and Pictographs"; };
  if cp >= 0x1F600 && cp <= 0x1F64F { return "Emoticons"; };
  if cp >= 0x1F680 && cp <= 0x1F6FF { return "Transport and Map Symbols"; };
  if cp >= 0x1F900 && cp <= 0x1F9FF { return "Supplemental Symbols and Pictographs"; };
  if cp >= 0x20000 && cp <= 0x2A6DF { return "CJK Unified Ideographs Extension B"; };
  "Undefined"
}

/// Returns the Unicode block name of the character `c`, e.g. 'A' yields
/// "Basic Latin" and 'Omega' yields "Greek and Coptic". Code points outside every
/// known block yield "Undefined".
/// Params: c the character to classify.
/// Returns: the block name.
/// Error case: none.
/// Complexity: O(number of table entries).
pub fn unicode_block(c: Char) -> Str {
  _block_name(to_int_from_char(c))
}

/// Returns the Unicode block name for the block code given as a code-point
/// hex string. Accepted forms: bare hex ("41", "1F600"), "0x..." and "U+..."
/// prefixed, and "\\u" escaped. Invalid or non-hex input yields "Undefined".
/// Params: code the code point as a hex string.
/// Returns: the block name, or "Undefined" when unparsable/unmapped.
/// Error case: "Undefined" for empty, non-hex, or unmapped input.
/// Complexity: O(|code| + number of table entries).
pub fn unicode_block_name(code: Str) -> Str
  requires: true  // extern char_at calls in the parsing loops (T002 confinement)
{
  let len = string.str_len(code);
  var start: Int = 0;
  if len >= 2 {
    let c = xiom_char_at(code, 0);
    if c == '0' {
      let c2 = xiom_char_at(code, 1);
      if c2 == 'x' {
        start = 2;
      };
    } elif c == 'U' {
      let c2 = xiom_char_at(code, 1);
      if c2 == '+' {
        start = 2;
      };
    } elif c == 'u' {
      let c2 = xiom_char_at(code, 1);
      if c2 == 'u' {
        start = 2;
      };
    } elif c == '\\' {
      start = 2;
    };
  };
  var cp: Int = 0;
  var started = false;
  var i = start;
  while i < len {
    let c = xiom_char_at(code, i);
    var hv: Int = -1;
    if c >= '0' && c <= '9' {
      hv = to_int_from_char(c) - 48;
    } elif c >= 'a' && c <= 'f' {
      hv = to_int_from_char(c) - 87;
    } elif c >= 'A' && c <= 'F' {
      hv = to_int_from_char(c) - 55;
    };
    if hv < 0 {
      return "Undefined";
    };
    cp = cp * 16 + hv;
    started = true;
    i = i + 1;
  };
  if !started {
    return "Undefined";
  };
  _block_name(cp)
}
