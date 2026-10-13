// XIOM - String: Reverse
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.reverse

// Depends on: xiom.string, xiom.char

// ============================================================================
// Reverse a string, its characters, or the order of its words. Character
// reversal is implemented locally (Unicode-aware): the flat string library's
// str_reverse is deliberately NOT delegated to, because calling a function
// named str_reverse emits every same-named definition in the loaded module
// set (see docs/COMPILER_BUGS.md) and the flat definition currently produces
// invalid LLVM IR. Word reversal keeps the whitespace runs of the input, only
// their order changes.
// ============================================================================

// Returns the raw byte at byte index `i` of `s`, as a Char (the historical
// byte-level semantics: multi-byte leads are not decoded here).
// Precondition: 0 <= i < s.len().
// Wave 127: raw read over the cached pointer -- xiom.string.byte_at strnlens
// the whole string per call, so the per-position scans were quadratic.
// Complexity: O(1).
fn _char_at(s: Str, i: Int) -> Char
  requires: true  // raw byte read; callers bound i against the cached len (T007)
{
  unsafe {
    let base: *UInt8 = s.c_str();
    return (((*(base + i)) as Int) & 0xFF) as Char;
  }
}

// Raw byte at byte index `i` of `s` (see _char_at).
// Complexity: O(1).
fn _raw_byte(s: Str, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against the cached len (T007)
{
  unsafe {
    let base: *UInt8 = s.c_str();
    return *(base + i);
  }
}

// Returns true when byte `b` is a UTF-8 continuation byte (0b10xxxxxx).
// Complexity: O(1).
fn _is_cont(b: UInt8) -> Bool {
  let v = b as Int;
  let masked = v & 0xC0;
  return masked == 0x80;
}

// Reverses the characters of `s`, iterating over UTF-8 character boundaries
// so multi-byte characters are preserved. Kept private so neither public entry
// point has to reference the name `str_reverse` (see the module header).
// Wave 127: one span pass collects the character ranges; the build pass copies
// the raw bytes of the spans in reverse (the previous implementation pushed a
// fresh str_slice per character and then concatenated per character -- the
// same n^2-allocation class as the wave-125/126 builder fixes).
fn _reverse_chars_impl(s: Str) -> Str {
  var starts = Vec[Int].new();
  var ends = Vec[Int].new();
  let len = xiom.string.str_len(s);
  var i: Int = 0;
  while i < len {
    var start = i;
    var adv: Int = 1;
    while start + adv < len && _is_cont(_raw_byte(s, start + adv)) {
      adv = adv + 1;
    };
    starts.push(start);
    ends.push(start + adv);
    i = start + adv;
  };
  var out: Vec[UInt8] = Vec[UInt8].new();
  var j: Int = starts.len();
  while j > 0 {
    j = j - 1;
    var k: Int = starts[j];
    let e = ends[j];
    while k < e {
      out.push(_raw_byte(s, k));
      k = k + 1;
    };
  };
  Str::from_utf8(out)
}

/// Reverses the characters of `s`, iterating over UTF-8 character boundaries
/// so multi-byte characters are preserved.
/// Returns a new string with the same byte length as `s`.
/// Complexity: O(|s|).
pub fn str_reverse(s: Str) -> Str
  ensures: result.len() == s.len()
{
  return _reverse_chars_impl(s);
}

/// Reverses the order of the whitespace-separated words of `s`. The runs of
/// whitespace between words are preserved as runs; only the token order is
/// reversed. Returns `s` unchanged when `s` has no words.
/// Wave 127: span pass + reverse raw-byte copy (was slice+concat per run).
/// Complexity: O(|s|).
pub fn str_reverse_words(s: Str) -> Str {
  var starts = Vec[Int].new();
  var ends = Vec[Int].new();
  let len = xiom.string.str_len(s);
  var i: Int = 0;
  while i < len {
    let first_ws = xiom.char.is_whitespace(_char_at(s, i));
    var run_start = i;
    while i < len && xiom.char.is_whitespace(_char_at(s, i)) == first_ws {
      i = i + 1;
    };
    starts.push(run_start);
    ends.push(i);
  };
  if starts.len() == 0 {
    return "";
  };
  var out: Vec[UInt8] = Vec[UInt8].new();
  var j: Int = starts.len();
  while j > 0 {
    j = j - 1;
    var k: Int = starts[j];
    let e = ends[j];
    while k < e {
      out.push(_raw_byte(s, k));
      k = k + 1;
    };
  };
  Str::from_utf8(out)
}

/// Alias of `str_reverse`: reverses the characters of `s`.
/// Complexity: O(|s|).
pub fn str_reverse_chars(s: Str) -> Str
  ensures: result.len() == s.len()
{
  return _reverse_chars_impl(s);
}
