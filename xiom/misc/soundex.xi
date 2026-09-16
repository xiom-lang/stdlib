// XIOM - Misc: Soundex
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.misc.soundex

// Depends on: xiom.text.similarity

// ============================================================================
// Soundex phonetic encoding -- CONSOLIDATED SHIM.
//
// The canonical implementation lives in `xiom.text.similarity` (the module
// `xiom.string.soundex` also delegates there). This module now delegates as
// well; before the compiler's delegation fix (round-22, m62) it carried a
// copy-paste duplicate because same-name qualified delegation miscompiled.
//
// Pre-1.0 semantic alignment (deliberate, documented): the old duplicate
// encoded the empty string as "0000"; the canonical encoding returns "".
// No smoke pinned the old value; every shared vector (Robert->R163,
// Rupert->R163, Ashcraft->A261, Tymczak->T522, Pfister->P236) is identical.
//
// Surface preserved: soundex, soundex_compare, soundex_encode, soundex_key,
// soundex_similarity, soundex_variants.
// ============================================================================

use xiom.text.similarity;
use xiom.char;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
}

// Map a character to its Soundex digit (1-6), or 0 if ignored.
fn _soundex_map(c: Char) -> Int {
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

/// Four-character American Soundex code of `s` (canonical: returns "" for
/// empty input). Params: s the word to encode. Returns: the code.
/// Complexity: O(|s|).
pub fn soundex(s: Str) -> Str {
  similarity.soundex(s)
}

/// Whether two strings share a Soundex code. O(|a| + |b|).
pub fn soundex_compare(a: Str, b: Str) -> Bool {
  similarity.soundex(a) == similarity.soundex(b)
}

/// Alias for soundex (kept for API compatibility). O(|s|).
pub fn soundex_encode(s: Str) -> Str {
  similarity.soundex(s)
}

/// Canonical comparison key for s: the standard Soundex code. O(|s|).
pub fn soundex_key(s: Str) -> Str {
  similarity.soundex(s)
}

/// Similarity in [0, 1] from the number of matching Soundex digits. O(1).
/// Canonical-aligned edge cases: two empty inputs score 1.0; exactly one
/// empty input scores 0.0 (the old duplicate compared "0000" codes instead).
pub fn soundex_similarity(a: Str, b: Str) -> Float64 {
  var ca = similarity.soundex(a);
  var cb = similarity.soundex(b);
  if ca.len() == 0 && cb.len() == 0 { return 1.0; }
  if ca.len() == 0 || cb.len() == 0 { return 0.0; }
  var match_count = 0;
  var limit = 4;
  if ca.len() < limit { limit = ca.len(); }
  if cb.len() < limit { limit = cb.len(); }
  var i = 0;
  while i < limit {
    if ca.char_at(i) == cb.char_at(i) {
      match_count = match_count + 1;
    }
    i = i + 1;
  }
  (match_count as Float64) / 4.0
}

/// Deterministic alternate Soundex codes for s. Returns a vector with the
/// standard code plus a code that encodes the first letter's own digit
/// (a common variant). O(|s|). The first element is always the canonical code.
pub fn soundex_variants(s: Str) -> Vec[Str] {
  var out = Vec[Str].new();
  var standard = similarity.soundex(s);
  out.push(standard);
  out.push(_soundex_with_first_digit(s, standard));
  out
}

/// Soundex variant that includes the first letter's encoding digit as the
/// second code position. Internal helper (canonical code passed in).
fn _soundex_with_first_digit(s: Str, standard: Str) -> Str {
  if standard.len() < 4 {
    return standard;
  }
  var first_digit = _soundex_map(s.char_at(0));
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
