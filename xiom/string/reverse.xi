// XIOM - String: Reverse
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

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

// Returns the character at byte index `i` of `s`.
// Precondition: 0 <= i < s.len().
// Complexity: O(1).
fn _char_at(s: Str, i: Int) -> Char {
  let b = xiom.string.byte_at(s, i) as Int;
  return b as Char;
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
fn _reverse_chars_impl(s: Str) -> Str {
  var chars = Vec[Str].new();
  let len = xiom.string.str_len(s);
  var i: Int = 0;
  while i < len {
    var start = i;
    var adv: Int = 1;
    while start + adv < len && _is_cont(xiom.string.byte_at(s, start + adv)) {
      adv = adv + 1;
    };
    chars.push(xiom.string.str_slice(s, start, start + adv));
    i = start + adv;
  };
  var result = "";
  var j: Int = chars.len() - 1;
  while j >= 0 {
    var ch = chars[j];
    result = xiom.string.str_concat(result, ch);
    j = j - 1;
  };
  result
}

// Reverses the characters of `s`, iterating over UTF-8 character boundaries
// so multi-byte characters are preserved.
// Returns a new string with the same byte length as `s`.
// Complexity: O(|s|).
pub fn str_reverse(s: Str) -> Str
  ensures: result.len() == s.len()
{
  return _reverse_chars_impl(s);
}

// Reverses the order of the whitespace-separated words of `s`. The runs of
// whitespace between words are preserved as runs; only the token order is
// reversed. Returns `s` unchanged when `s` has no words.
// Complexity: O(|s|).
pub fn str_reverse_words(s: Str) -> Str {
  var runs = Vec[Str].new();
  let len = xiom.string.str_len(s);
  var i: Int = 0;
  while i < len {
    let first_ws = xiom.char.is_whitespace(_char_at(s, i));
    var run_start = i;
    while i < len && xiom.char.is_whitespace(_char_at(s, i)) == first_ws {
      i = i + 1;
    };
    runs.push(xiom.string.str_slice(s, run_start, i));
  };
  if runs.len() == 0 {
    return "";
  };
  var result = "";
  var j: Int = runs.len() - 1;
  while j >= 0 {
    var r = runs[j];
    result = xiom.string.str_concat(result, r);
    j = j - 1;
  };
  result
}

// Alias of `str_reverse`: reverses the characters of `s`.
// Complexity: O(|s|).
pub fn str_reverse_chars(s: Str) -> Str
  ensures: result.len() == s.len()
{
  return _reverse_chars_impl(s);
}
