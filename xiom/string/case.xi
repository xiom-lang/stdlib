// XIOM - String: Case
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.case

// Depends on: xiom.string

// ============================================================================
// Case conversion of strings: upper, lower, title, capitalized, and
// camel/snake/kebab/pascal forms. All functions are pure and preserve the
// byte length of their input (ASCII-correct; non-ASCII characters pass
// through unchanged where the conversion has no mapping).
// ============================================================================

use xiom.string;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
}

// Returns the character at byte index `i` of `s`.
// Precondition: 0 <= i < s.len().
// Complexity: O(1).
fn _char_at(s: Str, i: Int) -> Char {
  let b = string.byte_at(s, i) as Int;
  return b as Char;
}

// Returns a one-character string holding the UTF-8 encoding of `c`.
// Complexity: O(1).
fn _char_to_str(c: Char) -> Str {
  let code = xiom.core.to_int_from_char(c);
  unsafe {
    if code <= 0x7F {
      var buf = malloc(2);
      buf[0] = code as UInt8;
      buf[1] = 0;
      return Str.from_cstring(buf);
    } elif code <= 0x7FF {
      var buf = malloc(3);
      buf[0] = (0xC0 | (code >> 6)) as UInt8;
      buf[1] = (0x80 | (code & 0x3F)) as UInt8;
      buf[2] = 0;
      return Str.from_cstring(buf);
    } elif code <= 0xFFFF {
      var buf = malloc(4);
      buf[0] = (0xE0 | (code >> 12)) as UInt8;
      buf[1] = (0x80 | ((code >> 6) & 0x3F)) as UInt8;
      buf[2] = (0x80 | (code & 0x3F)) as UInt8;
      buf[3] = 0;
      return Str.from_cstring(buf);
    } else {
      var buf = malloc(5);
      buf[0] = (0xF0 | (code >> 18)) as UInt8;
      buf[1] = (0x80 | ((code >> 12) & 0x3F)) as UInt8;
      buf[2] = (0x80 | ((code >> 6) & 0x3F)) as UInt8;
      buf[3] = (0x80 | (code & 0x3F)) as UInt8;
      buf[4] = 0;
      return Str.from_cstring(buf);
    };
  }
}

// Returns true when byte `b` is an ASCII alphanumeric character.
// Complexity: O(1).
fn _is_alnum_byte(b: UInt8) -> Bool {
  let v = b as Int;
  return (v >= 48 && v <= 57) || (v >= 65 && v <= 90) || (v >= 97 && v <= 122);
}

// Returns true when byte `b` is an ASCII uppercase letter.
// Complexity: O(1).
fn _is_upper_byte(b: UInt8) -> Bool {
  let v = b as Int;
  return v >= 65 && v <= 90;
}

// Returns true when byte `b` is an ASCII lowercase letter.
// Complexity: O(1).
fn _is_lower_byte(b: UInt8) -> Bool {
  let v = b as Int;
  return v >= 97 && v <= 122;
}

// Splits `s` into words. Word boundaries are non-alphanumeric characters,
// a lowercase-to-uppercase transition (hump, e.g. "helloWorld"), and an
// uppercase-run-to-lowercase transition (e.g. "URLValue").
// Complexity: O(|s|).
fn _split_words(s: Str) -> Vec[Str] {
  var result = Vec[Str].new();
  let len = string.str_len(s);
  var start: Int = 0;
  var i: Int = 0;
  while i < len {
    let b = string.byte_at(s, i);
    if !_is_alnum_byte(b) {
      if i > start {
        result.push(string.str_slice(s, start, i));
      };
      i = i + 1;
      start = i;
    } elif i > start && _is_upper_byte(b) && _is_lower_byte(string.byte_at(s, i - 1)) {
      result.push(string.str_slice(s, start, i));
      start = i;
      i = i + 1;
    } elif i >= 2 && i > start && _is_lower_byte(b) && _is_upper_byte(string.byte_at(s, i - 1)) && _is_upper_byte(string.byte_at(s, i - 2)) {
      result.push(string.str_slice(s, start, i));
      start = i;
      i = i + 1;
    } else {
      i = i + 1;
    };
  }
  if i > start {
    result.push(string.str_slice(s, start, i));
  };
  result
}

// Uppercases the first character of `w` and lowercases the rest.
// Complexity: O(|w|).
fn _capitalize(w: Str) -> Str {
  let len = string.str_len(w);
  if len == 0 {
    return "";
  };
  let first = string.str_upper(string.str_slice(w, 0, 1));
  if len == 1 {
    return first;
  };
  return string.str_concat(first, string.str_lower(string.str_slice(w, 1, len)));
}

// Joins the words of `s`, lowercased, with separator `sep`.
// Complexity: O(|s|).
fn _join_lower(s: Str, sep: Str) -> Str {
  var words = _split_words(s);
  var result = "";
  var i: Int = 0;
  while i < words.len() {
    if i > 0 {
      result = string.str_concat(result, sep);
    };
    var w = words[i];
    result = string.str_concat(result, string.str_lower(w));
    i = i + 1;
  };
  result
}

// Converts all characters of `s` to uppercase.
// Returns a new string with the same byte length as `s`.
// Complexity: O(|s|).
pub fn str_upper(s: Str) -> Str
  ensures: result.len() == s.len()
{
  return string.str_upper(s);
}

// Converts all characters of `s` to lowercase.
// Returns a new string with the same byte length as `s`.
// Complexity: O(|s|).
pub fn str_lower(s: Str) -> Str
  ensures: result.len() == s.len()
{
  return string.str_lower(s);
}

// Capitalizes the first letter of every word of `s`; remaining characters of
// each word are lowercased. Whitespace and separators are preserved.
// Returns a new string with the same byte length as `s`.
// Complexity: O(|s|).
pub fn str_title(s: Str) -> Str
  ensures: result.len() == s.len()
{
  return string.str_title_case(s);
}

// Swaps the case of every letter in `s`; characters that are neither
// uppercase nor lowercase are left unchanged.
// Returns a new string with the same byte length as `s`.
// Complexity: O(|s|).
pub fn str_swap_case(s: Str) -> Str
  ensures: result.len() == s.len()
{
  return string.str_swap_case(s);
}

// Uppercases the first character of `s` and lowercases the rest.
// Returns `s` unchanged when `s` is empty.
// Complexity: O(|s|).
pub fn str_capitalize(s: Str) -> Str
  ensures: result.len() == s.len()
{
  _capitalize(s)
}

// Capitalizes the first letter of each sentence of `s`. A sentence boundary is
// a '.', '!' or '?' character; the next alphabetic character is uppercased.
// Returns a new string with the same byte length as `s`.
// Complexity: O(|s|).
pub fn str_sentence_case(s: Str) -> Str
  ensures: result.len() == s.len()
{
  var result = "";
  let len = string.str_len(s);
  var cap_next = true;
  var i: Int = 0;
  while i < len {
    let c = _char_at(s, i);
    let bl = xiom.char.len_utf8(c);
    if xiom.char.is_alphabetic(c) {
      if cap_next {
        let uc = xiom.char.to_uppercase(c);
        result = string.str_concat(result, _char_to_str(uc));
      } else {
        result = string.str_concat(result, string.str_slice(s, i, i + bl));
      };
      cap_next = false;
    } else {
      result = string.str_concat(result, string.str_slice(s, i, i + bl));
      if c == '.' || c == '!' || c == '?' {
        cap_next = true;
      };
    };
    i = i + bl;
  };
  result
}

// Converts `s` to lowerCamelCase: the first word is lowercased and each
// following word is capitalized; separators are dropped.
// Complexity: O(|s|).
pub fn str_to_camel_case(s: Str) -> Str {
  var words = _split_words(s);
  if words.len() == 0 {
    return "";
  };
  var first = words[0];
  var result = string.str_lower(first);
  var i: Int = 1;
  while i < words.len() {
    var w = words[i];
    result = string.str_concat(result, _capitalize(w));
    i = i + 1;
  };
  result
}

// Converts `s` to snake_case: words are lowercased and joined with '_'.
// Complexity: O(|s|).
pub fn str_to_snake_case(s: Str) -> Str {
  _join_lower(s, "_")
}

// Converts `s` to kebab-case: words are lowercased and joined with '-'.
// Complexity: O(|s|).
pub fn str_to_kebab_case(s: Str) -> Str {
  _join_lower(s, "-")
}

// Converts `s` to PascalCase: every word is capitalized and joined without a
// separator.
// Complexity: O(|s|).
pub fn str_to_pascal_case(s: Str) -> Str {
  var words = _split_words(s);
  var result = "";
  var i: Int = 0;
  while i < words.len() {
    var w = words[i];
    result = string.str_concat(result, _capitalize(w));
    i = i + 1;
  };
  result
}
