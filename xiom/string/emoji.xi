// XIOM - String: Emoji
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.string.emoji

// Depends on: xiom.string, xiom.char

// ============================================================================
// Emoji detection and counting. The table below is a compact representative
// subset of the emoji blocks and components: emoticons, miscellaneous symbols
// and pictographs, transport and map symbols, supplemental symbols and
// pictographs, dingbats, enclosed alphanumerics (including regional-indicator
// flags), common misc symbols (star, heart, weather), the emoji presentation
// selector FE0F, skin-tone modifiers, ZWJ and the combining keycap. Some
// characters inside the broad 2300-23FF / 2600-26FF / 2B00-2BFF ranges default
// to text presentation in Unicode; this module counts them as emoji anyway
// (documented approximation).
// ============================================================================

use xiom.string;

/// True when `c` is an emoji character or emoji component codepoint: an emoji
/// block, a skin-tone modifier (U+1F3FB..U+1F3FF), the emoji presentation
/// selector (U+FE0F), ZWJ (U+200D) or the combining enclosing keycap
/// (U+20E3). See the header for the documented coverage.
/// Params: c the character to test.
/// Returns: true when c is emoji or an emoji component.
/// Error case: none.
/// Complexity: O(1).
pub fn unicode_is_emoji(c: Char) -> Bool {
  _is_emoji_cp(to_int_from_char(c))
}

/// Number of emoji characters and components in `s` (bases plus modifiers,
/// selectors, joiners). Full ZWJ sequences count each component separately.
/// Params: s the string to scan.
/// Returns: the count of emoji codepoints (>= 0).
/// Error case: none; malformed UTF-8 bytes are skipped.
/// Complexity: O(|s|).
pub fn unicode_count_emoji(s: Str) -> Int
  ensures: result >= 0
{
  let len = string.str_len(s);
  var count: Int = 0;
  var i: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      i = i + 1;
      continue;
    };
    if _is_emoji_cp(cp) {
      count = count + 1;
    };
    i = i + _char_len(cp);
  }
  count
}

/// True when `s` contains at least one emoji character or component.
/// Params: s the string to scan.
/// Returns: true when s contains an emoji.
/// Error case: none.
/// Complexity: O(|s|).
pub fn unicode_has_emoji(s: Str) -> Bool {
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp >= 0 {
      if _is_emoji_cp(cp) {
        return true;
      };
      i = i + _char_len(cp);
    } else {
      i = i + 1;
    };
  }
  false
}

// -- Private helpers ---------------------------------------------------------

/// Masked byte at `pos` (BUG 22 #10: `as Int` sign-extends UInt8).
fn _byte_at(s: Str, pos: Int) -> Int {
  let v = string.byte_at(s, pos) as Int;
  v & 0xFF
}

/// UTF-8 sequence length given the leading byte.
fn _seq_len(b0: Int) -> Int {
  if b0 <= 0x7F { return 1; };
  if (b0 & 0xE0) == 0xC0 { return 2; };
  if (b0 & 0xF0) == 0xE0 { return 3; };
  if (b0 & 0xF8) == 0xF0 { return 4; };
  1
}

/// UTF-8 byte length of a valid codepoint.
fn _char_len(cp: Int) -> Int {
  if cp <= 0x7F { return 1; };
  if cp <= 0x7FF { return 2; };
  if cp <= 0xFFFF { return 3; };
  4
}

/// Decode the codepoint at byte `pos`, or -1 on malformed input.
fn _decode(s: Str, pos: Int, len: Int) -> Int {
  let b0 = _byte_at(s, pos);
  let n = _seq_len(b0);
  if pos + n > len { return -1; };
  if n == 1 { return b0; };
  if n == 2 {
    let b1 = _byte_at(s, pos + 1);
    if (b1 & 0xC0) != 0x80 { return -1; };
    return ((b0 & 0x1F) << 6) | (b1 & 0x3F);
  };
  if n == 3 {
    let b1 = _byte_at(s, pos + 1);
    let b2 = _byte_at(s, pos + 2);
    if (b1 & 0xC0) != 0x80 { return -1; };
    if (b2 & 0xC0) != 0x80 { return -1; };
    let cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
    if cp >= 0xD800 && cp <= 0xDFFF { return -1; };
    return cp;
  };
  let b1 = _byte_at(s, pos + 1);
  let b2 = _byte_at(s, pos + 2);
  let b3 = _byte_at(s, pos + 3);
  if (b1 & 0xC0) != 0x80 { return -1; };
  if (b2 & 0xC0) != 0x80 { return -1; };
  if (b3 & 0xC0) != 0x80 { return -1; };
  ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F)
}

/// Emoji detection for one codepoint (compact table, see header).
/// NOTE (BUG 20): the classifier walks its table through a small recursive
/// helper; a straight-line range-check chain would be SIMD-vectorized by the
/// -O2 vectorizer into AVX-512 instructions that trap on CPUs without
/// AVX-512 (0xC000001D).
fn _is_emoji_cp(cp: Int) -> Bool {
  _emoji_r(cp, 0)
}

fn _emoji_r(cp: Int, i: Int) -> Bool {
  if i == 0 {
    if cp >= 0x1F600 && cp <= 0x1F64F { return true; };
  };
  if i == 1 {
    if cp >= 0x1F300 && cp <= 0x1F5FF { return true; };
  };
  if i == 2 {
    if cp >= 0x1F680 && cp <= 0x1F6FF { return true; };
  };
  if i == 3 {
    if cp >= 0x1F900 && cp <= 0x1F9FF { return true; };
  };
  if i == 4 {
    if cp >= 0x1FA00 && cp <= 0x1FAFF { return true; };
  };
  if i == 5 {
    if cp >= 0x1F100 && cp <= 0x1F1FF { return true; };
  };
  if i == 6 {
    if cp >= 0x2600 && cp <= 0x26FF { return true; };
  };
  if i == 7 {
    if cp >= 0x2700 && cp <= 0x27BF { return true; };
  };
  if i == 8 {
    if cp >= 0x2B00 && cp <= 0x2BFF { return true; };
  };
  if i == 9 {
    if cp >= 0x2300 && cp <= 0x23FF { return true; };
  };
  if i == 10 {
    if cp >= 0x1F3FB && cp <= 0x1F3FF { return true; };
  };
  if i == 11 {
    if cp == 0xFE0F { return true; };
  };
  if i == 12 {
    if cp == 0x200D { return true; };
  };
  if i == 13 {
    if cp == 0x20E3 { return true; };
  };
  if i < 13 {
    return _emoji_r(cp, i + 1);
  };
  false
}
