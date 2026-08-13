// XIOM - Misc: Soundex
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.misc.soundex

// Depends on: xiom.string

// ============================================================================
// Classic American Soundex encoding, comparison, similarity and variants.
// ============================================================================

extern "C" {
    fn malloc(size: UInt) -> *UInt8;
}

use xiom.char;

/// Map a character to its Soundex digit (1-6), or 0 if ignored.
fn soundex_map(c: Char) -> Int {
  var v = xiom.char.to_uppercase(c) as Int;
  if v == 'B' as Int || v == 'F' as Int || v == 'P' as Int || v == 'V' as Int { return 1; }
  if v == 'C' as Int || v == 'G' as Int || v == 'J' as Int || v == 'K' as Int ||
     v == 'Q' as Int || v == 'S' as Int || v == 'X' as Int || v == 'Z' as Int { return 2; }
  if v == 'D' as Int || v == 'T' as Int { return 3; }
  if v == 'L' as Int { return 4; }
  if v == 'M' as Int || v == 'N' as Int { return 5; }
  if v == 'R' as Int { return 6; }
  0
}

/// The classic 4-character American Soundex code for s. O(len).
/// Returns "0000" when s contains no letters. The first letter is kept
/// verbatim (uppercased); subsequent letters map to 1-6 with consecutive
/// duplicates and H/W separators handled per the standard.
pub fn soundex(s: Str) -> Str {
  var len = s.len();
  if len == 0 {
    return "0000";
  }
  var first = 0;
  var i = 0;
  var found = false;
  while i < len && !found {
    var c = s.char_at(i);
    if xiom.char.is_alphabetic(c) {
      first = xiom.char.to_uppercase(c) as Int;
      i = i + 1;
      found = true;
    } else {
      i = i + 1;
    }
  }
  if first == 0 {
    return "0000";
  }
  var prev_code = soundex_map(s.char_at(i - 1));
  var count = 0;
  unsafe {
    var buf = malloc(5 as UInt);
    buf[0] = first as UInt8;
    count = 1;
    while i < len && count < 4 {
      var c = s.char_at(i);
      var d = soundex_map(c);
      if d > 0 && d != prev_code {
        buf[count] = (48 + d) as UInt8;
        count = count + 1;
        prev_code = d;
      } elif d == 0 {
        var v = xiom.char.to_uppercase(c) as Int;
        if v != 'H' as Int && v != 'W' as Int {
          prev_code = 0;
        }
      }
      i = i + 1;
    }
    while count < 4 {
      buf[count] = 48;
      count = count + 1;
    }
    buf[4] = 0;
    return Str.from_cstring(buf);
  }
}

/// Whether two strings share a Soundex code. O(len_a + len_b).
pub fn soundex_compare(a: Str, b: Str) -> Bool {
  var ca = soundex(a);
  var cb = soundex(b);
  soundex_key_eq(ca, cb)
}

/// Alias for soundex with pre-lowercasing of the input. O(len).
/// Lowercasing does not change the code, so this equals soundex for ASCII
/// input; it is provided for API compatibility.
pub fn soundex_encode(s: Str) -> Str {
  soundex(s)
}

/// Similarity in [0, 1] from the number of matching Soundex digits. O(1).
/// 1.0 when the codes are identical, 0.5 when two digits match, etc.
pub fn soundex_similarity(a: Str, b: Str) -> Float64 {
  var ca = soundex(a);
  var cb = soundex(b);
  var match_count = 0;
  var i = 0;
  while i < 4 {
    if ca.char_at(i) == cb.char_at(i) {
      match_count = match_count + 1;
    }
    i = i + 1;
  }
  (match_count as Float64) / 4.0
}

/// Deterministic alternate Soundex codes for s. Returns a vector with the
/// standard code plus a code that encodes the first letter's own digit
/// (a common variant). O(len). Treat the result as opaque; the first element
/// is always the canonical soundex code.
pub fn soundex_variants(s: Str) -> Vec[Str] {
  var out = Vec[Str].new();
  var standard = soundex(s);
  out.push(standard);
  out.push(soundex_with_first_digit(s));
  out
}

/// Canonical comparison key for s: the standard Soundex code. O(len).
pub fn soundex_key(s: Str) -> Str {
  soundex(s)
}

/// Equal-length byte comparison of two 4-char Soundex codes.
fn soundex_key_eq(a: Str, b: Str) -> Bool {
  if a.len() != b.len() { return false; }
  var i = 0;
  while i < a.len() {
    if a.char_at(i) != b.char_at(i) {
      return false;
    }
    i = i + 1;
  }
  true
}

/// Soundex variant that includes the first letter's encoding digit as the
/// second code position. Internal helper.
fn soundex_with_first_digit(s: Str) -> Str {
  var standard = soundex(s);
  var first_digit = soundex_map(s.char_at(0));
  if first_digit == 0 {
    return standard;
  }
  unsafe {
    var buf = malloc(5 as UInt);
    buf[0] = standard.char_at(0) as UInt8;
    buf[1] = (48 + first_digit) as UInt8;
    buf[2] = standard.char_at(2) as UInt8;
    buf[3] = standard.char_at(3) as UInt8;
    buf[4] = 0;
    return Str.from_cstring(buf);
  }
}
