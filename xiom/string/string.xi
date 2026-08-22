// XIOM -- String Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_char_at(s: Str, pos: Int) -> Char;
  // round-14 (BUG 26 #7): the RAW BYTE accessor -- xiom_char_at now
  // returns the decoded UTF-8 CODEPOINT, which broke byte_at (the old
  // byte_at reused xiom_char_at and double-decoded multibyte strings).
  // Declared Int (i64) -- the runtime's return -- the wrapper casts.
  fn xiom_byte_at(s: Str, pos: Int) -> Int;
}

pub fn str_len(s: Str) -> Int {
  s.len()
}

pub fn str_concat(a: Str, b: Str) -> Str
  ensures: result.len() == a.len() + b.len()
{
  let len_a = a.len();
  let len_b = b.len();
  let total = len_a + len_b;
  unsafe {
    var buf = malloc(total + 1);
    var i: Int = 0;
    while i < len_a {
      buf[i] = byte_at(a, i);
      i = i + 1;
    }
    var j: Int = 0;
    while j < len_b {
      buf[len_a + j] = byte_at(b, j);
      j = j + 1;
    }
    buf[total] = 0;
    return Str.from_cstring(buf);
  }
}

pub fn str_slice(s: Str, start: Int, end: Int) -> Str
{
  let len = s.len();
  var s_start = start;
  var s_end = end;
  if s_start < 0 { s_start = 0; };
  if s_end > len { s_end = len; };
  if s_start >= s_end { return ""; };
  let slice_len = s_end - s_start;
  unsafe {
    var buf = malloc(slice_len + 1);
    var i: Int = 0;
    while i < slice_len {
      buf[i] = byte_at(s, s_start + i);
      i = i + 1;
    }
    buf[slice_len] = 0;
    return Str.from_cstring(buf);
  }
}

pub fn str_contains(s: Str, substr: Str) -> Bool {
  let result = index_of(s, substr);
  result.is_some
}

pub fn str_starts_with(s: Str, prefix: Str) -> Bool {
  let prefix_len = prefix.len();
  if prefix_len > s.len() {
    return false;
  };
  str_slice(s, 0, prefix_len) == prefix
}

pub fn str_ends_with(s: Str, suffix: Str) -> Bool {
  let suffix_len = suffix.len();
  let s_len = s.len();
  if suffix_len > s_len {
    return false;
  };
  str_slice(s, s_len - suffix_len, s_len) == suffix
}

pub fn str_split(s: Str, delimiter: Str) -> Vec[Str]
  ensures:  result.len() >= 1  // always at least one element
{
  var result = Vec[Str].new();
  let delim_len = delimiter.len();
  let s_len = s.len();
  if delim_len == 0 {
    var i: Int = 0;
    while i < s_len {
      result.push(str_slice(s, i, i + 1));
      i = i + 1;
    }
    if result.len() == 0 {
      result.push("");
    }
    return result;
  };
  var start: Int = 0;
  var pos: Int = 0;
  while pos < s_len {
    if pos + delim_len <= s_len && str_slice(s, pos, pos + delim_len) == delimiter {
      result.push(str_slice(s, start, pos));
      pos = pos + delim_len;
      start = pos;
    } else {
      pos = pos + 1;
    };
  }
  result.push(str_slice(s, start, s_len));
  result
}

pub fn str_trim(s: Str) -> Str
  ensures: result.len() <= s.len()  // trim never increases length
{
  let len = s.len();
  var start: Int = 0;
  var end: Int = len;
  while start < len && xiom.char.is_whitespace(xiom_char_at(s, start)) {
    start = start + 1;
  }
  while end > start && xiom.char.is_whitespace(xiom_char_at(s, end - 1)) {
    end = end - 1;
  }
  str_slice(s, start, end)
}

pub fn str_to_int(s: Str) -> Result[Int, Str]
{
  xiom.core.to_int_from_str(s)
}

pub fn str_to_float(s: Str) -> Result[Float64, Str]
{
  xiom.core.to_float_from_str(s)
}

pub fn str_upper(s: Str) -> Str
  ensures: result.len() == s.len()
{
  let len = s.len();
  unsafe {
    var buf = malloc(len + 1);
    var i: Int = 0;
    while i < len {
      let c = xiom_char_at(s, i);
      buf[i] = xiom.char.to_uppercase(c) as UInt8;
      i = i + 1;
    }
    buf[len] = 0;
    return Str.from_cstring(buf);
  }
}

pub fn str_lower(s: Str) -> Str
  ensures: result.len() == s.len()
{
  let len = s.len();
  unsafe {
    var buf = malloc(len + 1);
    var i: Int = 0;
    while i < len {
      let c = xiom_char_at(s, i);
      buf[i] = xiom.char.to_lowercase(c) as UInt8;
      i = i + 1;
    }
    buf[len] = 0;
    return Str.from_cstring(buf);
  }
}

pub fn format(fmt: Str) -> Str {
  fmt
}

pub fn format1(fmt: Str, arg: Str) -> Str
  ensures: result.len() >= fmt.len() - 2 + arg.len()
{
  let idx_opt = index_of(fmt, "{}");
  match idx_opt {
    Some(idx) => {
      let before = str_slice(fmt, 0, idx);
      let after = str_slice(fmt, idx + 2, str_len(fmt));
      str_concat(str_concat(before, arg), after)
    };
    None => fmt;
  }
}

pub fn format2(fmt: Str, arg1: Str, arg2: Str) -> Str {
  let s = format1(fmt, arg1);
  format1(s, arg2)
}

pub fn byte_at(s: Str, pos: Int) -> UInt8 {
  (xiom_byte_at(s, pos)) as UInt8
}

pub fn char_at(s: Str, pos: Int) -> Option[Char]
  ensures: result is Some => pos >= 0 && pos < s.char_count()
  ensures: result is None => pos < 0 || pos >= s.char_count()
{
  if pos < 0 || pos >= s.len() {
    return None;
  };
  Some(xiom_char_at(s, pos))
}

pub fn index_of(s: Str, substr: Str) -> Option[Int]
  requires: substr.len() > 0
  ensures:  result is Some => result >= 0 && result < s.len()
{
  let s_len = s.len();
  let sub_len = substr.len();
  if sub_len > s_len {
    return None;
  };
  if sub_len == 0 {
    return Some(0);
  };
  var i: Int = 0;
  while i <= s_len - sub_len {
    if str_slice(s, i, i + sub_len) == substr {
      return Some(i);
    };
    i = i + 1;
  };
  None
}

pub fn last_index_of(s: Str, substr: Str) -> Option[Int] {
  let s_len = s.len();
  let sub_len = substr.len();
  if sub_len > s_len {
    return None;
  };
  if sub_len == 0 {
    return Some(s_len);
  };
  var i: Int = s_len - sub_len;
  while i >= 0 {
    if str_slice(s, i, i + sub_len) == substr {
      return Some(i);
    };
    i = i - 1;
  };
  None
}

pub fn replace(s: Str, from: Str, to: Str) -> Str
{
  let from_len = from.len();
  if from_len == 0 {
    return s;
  };
  var result = "";
  var pos: Int = 0;
  let s_len = s.len();
  loop {
    if pos >= s_len {
      break;
    };
    let rem = str_slice(s, pos, s_len);
    let idx_opt = index_of(rem, from);
    match idx_opt {
      Some(idx) => {
        result = str_concat(result, str_slice(s, pos, pos + idx));
        result = str_concat(result, to);
        pos = pos + idx + from_len;
      };
      None => {
        result = str_concat(result, str_slice(s, pos, s_len));
        break;
      };
    };
  }
  result
}

pub fn lines(s: Str) -> Vec[Str] {
  str_split(s, "\n")
}

pub fn words(s: Str) -> Vec[Str] {
  var result = Vec[Str].new();
  let len = s.len();
  var i: Int = 0;
  while i < len {
    while i < len && xiom.char.is_whitespace(xiom_char_at(s, i)) {
      i = i + 1;
    }
    if i < len {
      var start = i;
      while i < len && !xiom.char.is_whitespace(xiom_char_at(s, i)) {
        i = i + 1;
      }
      result.push(str_slice(s, start, i));
    };
  }
  result
}

pub fn is_empty(s: Str) -> Bool {
  s.len() == 0
}

// Method form: `x.is_empty()`. The plain fn above is NOT a method -- the
// compiler's receiver-typed method lookup needs the Str receiver decl
// (method-form `x.is_empty()` otherwise falls through to a Vec/array
// is_empty leaf or a stub and always returns false).
pub fn Str.is_empty(self) -> Bool {
  self.len() == 0
}

pub fn char_count(s: Str) -> Int {
  var count: Int = 0;
  let len = s.len();
  var i: Int = 0;
  while i < len {
    let c = xiom_char_at(s, i);
    let byte_len = xiom.char.len_utf8(c);
    i = i + byte_len;
    count = count + 1;
  }
  count
}

pub fn byte_count(s: Str) -> Int {
  s.len()
}

// --------------------------------------------------
//  Extended String Functions
// --------------------------------------------------

// -- Search --

// Returns the first byte index of needle in haystack, or None if not found.
// O(n*m) naive search. For an empty needle, returns Some(0).
pub fn str_index_of(haystack: Str, needle: Str) -> Option[Int]
  requires: needle.len() > 0
{
  index_of(haystack, needle)
}

// Returns the last byte index of needle in haystack, or None if not found.
// O(n*m) reverse naive search. For an empty needle, returns Some(haystack.len()).
pub fn str_rindex_of(haystack: Str, needle: Str) -> Option[Int] {
  last_index_of(haystack, needle)
}

// -- Replace --

// Replaces every occurrence of `from` with `to` in `s`.
// O(n*m) where n = |s|, m = |from|. If `from` is empty, returns `s` unchanged.
pub fn str_replace_all(s: Str, from_needle: Str, to_replacement: Str) -> Str
  requires: from_needle.len() > 0
{
  replace(s, from_needle, to_replacement)
}

// -- Repeat & Pad --

// Repeats `s` `n` times. Returns empty string if n <= 0.
// O(n * |s|) using repeated concatenation.
pub fn str_repeat(s: Str, n: Int) -> Str {
  if n <= 0 {
    return "";
  };
  var result = "";
  var i: Int = 0;
  while i < n {
    result = str_concat(result, s);
    i = i + 1;
  };
  result
}

// Left-pads `s` with `pad` until the string reaches `width` bytes.
// If `s` is already >= `width` in bytes, returns `s` unchanged.
// O(width - |s|). Only handles single-byte pad characters correctly.
pub fn str_pad_left(s: Str, width: Int, pad: Char) -> Str {
  let s_len = s.len();
  if s_len >= width {
    return s;
  };
  let pad_len = width - s_len;
  var pad_str = "";
  var i: Int = 0;
  while i < pad_len {
    unsafe {
      var buf = malloc(2);
      buf[0] = pad as UInt8;
      buf[1] = 0;
      pad_str = str_concat(pad_str, Str.from_cstring(buf));
    };
    i = i + 1;
  };
  str_concat(pad_str, s)
}

// Right-pads `s` with `pad` until the string reaches `width` bytes.
// If `s` is already >= `width` in bytes, returns `s` unchanged.
// O(width - |s|). Only handles single-byte pad characters correctly.
pub fn str_pad_right(s: Str, width: Int, pad: Char) -> Str {
  let s_len = s.len();
  if s_len >= width {
    return s;
  };
  var result = s;
  var i: Int = s_len;
  while i < width {
    unsafe {
      var buf = malloc(2);
      buf[0] = pad as UInt8;
      buf[1] = 0;
      result = str_concat(result, Str.from_cstring(buf));
    };
    i = i + 1;
  };
  result
}

// -- Strip --

// If `s` starts with `prefix`, returns `Some(s without prefix)`.
// Otherwise returns `None`.
// O(|prefix|).
pub fn str_strip_prefix(s: Str, prefix: Str) -> Option[Str] {
  if str_starts_with(s, prefix) {
    let remaining = str_slice(s, prefix.len(), s.len());
    return Some(remaining);
  };
  None
}

// If `s` ends with `suffix`, returns `Some(s without suffix)`.
// Otherwise returns `None`.
// O(|suffix|).
pub fn str_strip_suffix(s: Str, suffix: Str) -> Option[Str] {
  if str_ends_with(s, suffix) {
    let remaining = str_slice(s, 0, s.len() - suffix.len());
    return Some(remaining);
  };
  None
}

// -- Escape/Unescape --

// Escapes special characters (\n, \t, \", \\, \r) in `s`.
// Returns a new string with escape sequences replaced by their literal representations.
// O(|s|). For multi-byte UTF-8 chars, only \n \t \" \\ \r are escaped.
pub fn str_escape(s: Str) -> Str {
  var result = "";
  let len = s.len();
  var i: Int = 0;
  while i < len {
    let c = xiom_char_at(s, i);
    if c == '\n' {
      result = str_concat(result, "\\n");
    } elif c == '\t' {
      result = str_concat(result, "\\t");
    } elif c == '\"' {
      result = str_concat(result, "\\\"");
    } elif c == '\\' {
      result = str_concat(result, "\\\\");
    } elif c == '\r' {
      result = str_concat(result, "\\r");
    } else {
      unsafe {
        var buf = malloc(5);
        var byte_len = xiom.char.len_utf8(c);
        var code = xiom.char.to_int_from_char(c);
        if code <= 0x7F {
          buf[0] = code as UInt8;
          buf[1] = 0;
        } elif code <= 0x7FF {
          buf[0] = (0xC0 | (code >> 6)) as UInt8;
          buf[1] = (0x80 | (code & 0x3F)) as UInt8;
          buf[2] = 0;
        } elif code <= 0xFFFF {
          buf[0] = (0xE0 | (code >> 12)) as UInt8;
          buf[1] = (0x80 | ((code >> 6) & 0x3F)) as UInt8;
          buf[2] = (0x80 | (code & 0x3F)) as UInt8;
          buf[3] = 0;
        } else {
          buf[0] = (0xF0 | (code >> 18)) as UInt8;
          buf[1] = (0x80 | ((code >> 12) & 0x3F)) as UInt8;
          buf[2] = (0x80 | ((code >> 6) & 0x3F)) as UInt8;
          buf[3] = (0x80 | (code & 0x3F)) as UInt8;
          buf[4] = 0;
        };
        result = str_concat(result, Str.from_cstring(buf));
      };
    };
    let byte_adv = xiom.char.len_utf8(c);
    i = i + byte_adv;
  };
  result
}

// Un-escapes a string that contains escape sequences like \n \t \" \\ \r.
// Returns the string with literal escape sequences replaced by the actual characters.
// O(|s|). Unrecognised escape sequences are left unchanged.
pub fn str_unescape(s: Str) -> Str {
  var result = "";
  let len = s.len();
  var i: Int = 0;
  while i < len {
    let c = xiom_char_at(s, i);
    if c == '\\' && i + 1 < len {
      let next = xiom_char_at(s, i + 1);
      if next == 'n' {
        result = str_concat(result, "\n");
        i = i + 2;
      } elif next == 't' {
        result = str_concat(result, "\t");
        i = i + 2;
      } elif next == '\"' {
        result = str_concat(result, "\"");
        i = i + 2;
      } elif next == '\\' {
        result = str_concat(result, "\\");
        i = i + 2;
      } elif next == 'r' {
        result = str_concat(result, "\r");
        i = i + 2;
      } else {
        result = str_concat(result, str_slice(s, i, i + 1));
        i = i + 1;
      };
    } else {
      var byte_adv = xiom.char.len_utf8(c);
      result = str_concat(result, str_slice(s, i, i + byte_adv));
      i = i + byte_adv;
    };
  };
  result
}

// -- Case --

// Converts `s` to Title Case: first character of each space-separated word
// is uppercased, remaining characters are lowercased.
// O(|s|) byte-by-byte. Only handles ASCII letter case correctly.
pub fn str_title_case(s: Str) -> Str {
  let len = s.len();
  var new_word = true;
  unsafe {
    var buf = malloc(len + 1);
    var i: Int = 0;
    while i < len {
      let c = xiom_char_at(s, i);
      if xiom.char.is_whitespace(c) {
        new_word = true;
        buf[i] = c as UInt8;
      } elif new_word {
        buf[i] = xiom.char.to_uppercase(c) as UInt8;
        new_word = false;
      } else {
        buf[i] = xiom.char.to_lowercase(c) as UInt8;
      };
      i = i + 1;
    };
    buf[len] = 0;
    return Str.from_cstring(buf);
  }
}

// Swaps the case of every character in `s`: uppercase becomes lowercase and
// vice versa. Characters that are neither are left unchanged.
// O(|s|) byte-by-byte. Only handles ASCII letter case correctly.
pub fn str_swap_case(s: Str) -> Str {
  let len = s.len();
  unsafe {
    var buf = malloc(len + 1);
    var i: Int = 0;
    while i < len {
      let c = xiom_char_at(s, i);
      if xiom.char.is_uppercase(c) {
        buf[i] = xiom.char.to_lowercase(c) as UInt8;
      } elif xiom.char.is_lowercase(c) {
        buf[i] = xiom.char.to_uppercase(c) as UInt8;
      } else {
        buf[i] = c as UInt8;
      };
      i = i + 1;
    };
    buf[len] = 0;
    return Str.from_cstring(buf);
  }
}

// -- Predicates --

// Returns true if `s` has zero length.
// O(1).
pub fn str_is_empty(s: Str) -> Bool {
  s.len() == 0
}

// -- Reverse --

// Reverses the characters in `s`. Unicode-aware: iterates by
// proper UTF-8 character boundaries.
// O(|s|) -- two passes (collect + build).
pub fn str_reverse(s: Str) -> Str {
  let len = s.len();
  if len == 0 {
    return "";
  };
  var total_bytes: Int = 0;
  var i: Int = 0;
  while i < len {
    let c = xiom_char_at(s, i);
    total_bytes = total_bytes + xiom.char.len_utf8(c);
    i = i + xiom.char.len_utf8(c);
  };
  unsafe {
    var buf = malloc(total_bytes + 1);
    var out_pos: Int = 0;
    var rev_start: Int = len;
    while rev_start > 0 {
      var j: Int = 0;
      while j < rev_start {
        let c = xiom_char_at(s, j);
        let bl = xiom.char.len_utf8(c);
        if j + bl == rev_start {
          var code = xiom.char.to_int_from_char(c);
          if code <= 0x7F {
            buf[out_pos] = code as UInt8;
            out_pos = out_pos + 1;
          } elif code <= 0x7FF {
            buf[out_pos] = (0xC0 | (code >> 6)) as UInt8;
            buf[out_pos + 1] = (0x80 | (code & 0x3F)) as UInt8;
            out_pos = out_pos + 2;
          } elif code <= 0xFFFF {
            buf[out_pos] = (0xE0 | (code >> 12)) as UInt8;
            buf[out_pos + 1] = (0x80 | ((code >> 6) & 0x3F)) as UInt8;
            buf[out_pos + 2] = (0x80 | (code & 0x3F)) as UInt8;
            out_pos = out_pos + 3;
          } else {
            buf[out_pos] = (0xF0 | (code >> 18)) as UInt8;
            buf[out_pos + 1] = (0x80 | ((code >> 12) & 0x3F)) as UInt8;
            buf[out_pos + 2] = (0x80 | ((code >> 6) & 0x3F)) as UInt8;
            buf[out_pos + 3] = (0x80 | (code & 0x3F)) as UInt8;
            out_pos = out_pos + 4;
          };
          rev_start = j;
          break;
        };
        j = j + bl;
      };
    };
    buf[total_bytes] = 0;
    return Str.from_cstring(buf);
  }
}

// -- Count --

// Counts the number of Unicode characters in `s` using xiom_char_at.
// Unicode-aware: advances by the byte length of each character.
// O(|s|).
pub fn str_count_chars(s: Str) -> Int {
  char_count(s)
}

// -- Truncate --

// Truncates `s` at the given byte position `max_bytes`, ensuring the result
// does not split a multi-byte UTF-8 character. If `max_bytes` lands in the
// middle of a multi-byte sequence, the result is truncated before that
// character begins.
// O(|s|).
pub fn str_truncate_utf8(s: Str, max_bytes: Int) -> Str {
  let len = s.len();
  if max_bytes >= len {
    return s;
  };
  if max_bytes <= 0 {
    return "";
  };
  var i: Int = 0;
  var last_valid: Int = 0;
  while i < len && i < max_bytes {
    let c = xiom_char_at(s, i);
    let bl = xiom.char.len_utf8(c);
    if i + bl <= max_bytes {
      last_valid = i + bl;
    } else {
      break;
    };
    i = i + bl;
  };
  str_slice(s, 0, last_valid)
}

// -- Center --

// Centers `s` within a field of `width` bytes by adding spaces on both sides.
// If an odd number of spaces are needed, the extra space goes on the right.
// Only handles single-byte pad characters correctly.
// O(width).
pub fn str_center(s: Str, width: Int) -> Str {
  let s_len = s.len();
  if s_len >= width {
    return s;
  };
  let total_pad = width - s_len;
  let left_pad = total_pad / 2;
  let right_pad = total_pad - left_pad;
  var result = "";
  var i: Int = 0;
  while i < left_pad {
    result = str_concat(result, " ");
    i = i + 1;
  };
  result = str_concat(result, s);
  var j: Int = 0;
  while j < right_pad {
    result = str_concat(result, " ");
    j = j + 1;
  };
  result
}

// -- Multi-pattern Tests --

// Returns true if `s` starts with any of the given prefixes.
// O(n * k) where n = |s|, k = prefixes.len().
pub fn str_starts_with_any(s: Str, prefixes: &Vec[Str]) -> Bool {
  var i: Int = 0;
  while i < prefixes.len() {
    if str_starts_with(s, prefixes[i]) {
      return true;
    };
    i = i + 1;
  };
  false
}

// Returns true if `s` ends with any of the given suffixes.
// O(n * k) where n = |s|, k = suffixes.len().
pub fn str_ends_with_any(s: Str, suffixes: &Vec[Str]) -> Bool {
  var i: Int = 0;
  while i < suffixes.len() {
    if str_ends_with(s, suffixes[i]) {
      return true;
    };
    i = i + 1;
  };
  false
}

// Returns true if `s` contains any of the given substrings.
// O(n * m * k) where n = |s|, m = max substring length, k = needles.len().
pub fn str_contains_any(s: Str, needles: &Vec[Str]) -> Bool {
  var i: Int = 0;
  while i < needles.len() {
    if str_contains(s, needles[i]) {
      return true;
    };
    i = i + 1;
  };
  false
}

// ============================================================================
// 2026-08-11 additions: translate / rot / caesar / atbash / abbreviate /
// obfuscate (ASCII; non-ASCII bytes pass through unchanged for the ciphers)
// ============================================================================

// Build a one-char string from a printable ASCII byte value (32..126).
// Bytes outside that range render as "?" -- the ciphers below only produce
// printable output for printable input (documented).
fn _mk_byte(v: Int) -> Str {
  var table = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
  if v >= 32 && v <= 126 {
    return str_slice(table, v - 32, v - 31);
  }
  return str_slice("?", 0, 1);
}

/// Translate characters per the `tr` utility: each char of `s` found in
/// `from` is replaced by the char at the same position in `to`; chars beyond
/// `to`'s length are REMOVED; chars not in `from` pass through. ASCII.
pub fn str_translate(s: Str, from: Str, to: Str) -> Str {
  var result = "";
  var i: Int = 0;
  while i < str_len(s) {
    var c = byte_at(s, i);
    var j: Int = 0;
    var found = false;
    while j < str_len(from) {
      if byte_at(from, j) == c {
        found = true;
        break;
      }
      j = j + 1;
    }
    if !found {
      result = str_concat(result, str_slice(s, i, i + 1));
    } elif j < str_len(to) {
      result = str_concat(result, str_slice(to, j, j + 1));
    }
    // j >= len(to): removed
    i = i + 1;
  }
  return result;
}

/// ROT13 over A-Z/a-z (ASCII).
pub fn str_rot13(s: Str) -> Str {
  return str_caesar(s, 13);
}

/// ROT47 over ASCII 33..126 (all printable chars rotate by 47).
pub fn str_rot47(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  while i < str_len(s) {
    var b = byte_at(s, i) as Int;
    if b >= 33 && b <= 126 {
      var v = b - 33;
      v = (v + 47) % 94;
      result = str_concat(result, _mk_byte(v + 33));
    } else {
      result = str_concat(result, str_slice(s, i, i + 1));
    }
    i = i + 1;
  }
  return result;
}

/// Caesar shift over A-Z/a-z (ASCII). Negative shifts go backwards; the
/// shift wraps mod 26.
pub fn str_caesar(s: Str, shift: Int) -> Str {
  var result = "";
  var sh = shift % 26;
  if sh < 0 { sh = sh + 26; }
  var i: Int = 0;
  while i < str_len(s) {
    var b = byte_at(s, i) as Int;
    if b >= 97 && b <= 122 {
      var v = (b - 97 + sh) % 26 + 97;
      result = str_concat(result, _mk_byte(v));
    } elif b >= 65 && b <= 90 {
      var v2 = (b - 65 + sh) % 26 + 65;
      result = str_concat(result, _mk_byte(v2));
    } else {
      result = str_concat(result, str_slice(s, i, i + 1));
    }
    i = i + 1;
  }
  return result;
}

/// Atbash: a<->z, A<->Z mirror (ASCII). Non-letters pass through.
pub fn str_atbash(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  while i < str_len(s) {
    var b = byte_at(s, i) as Int;
    if b >= 97 && b <= 122 {
      result = str_concat(result, _mk_byte(97 + (122 - b)));
    } elif b >= 65 && b <= 90 {
      result = str_concat(result, _mk_byte(65 + (90 - b)));
    } else {
      result = str_concat(result, str_slice(s, i, i + 1));
    }
    i = i + 1;
  }
  return result;
}

/// Abbreviate with a middle ellipsis: keeps `(max_len-3)/2` chars from the
/// front and the rest from the back ("..." as "..."). Strings at or under
/// max_len are returned unchanged; max_len < 4 falls back to truncation.
pub fn str_abbreviate(s: Str, max_len: Int) -> Str {
  var len = str_len(s);
  if len <= max_len {
    return s;
  }
  if max_len < 4 {
    return str_slice(s, 0, max_len);
  }
  var keep = max_len - 3;
  var front = (keep + 1) / 2;
  var back = keep - front;
  var head = str_slice(s, 0, front);
  var tail = str_slice(s, len - back, len);
  return str_concat(str_concat(head, "..."), tail);
}

/// Obfuscate: keep the first `visible` chars, mask the rest with '*'
/// (e.g. str_obfuscate("secret", 3) == "sec***"). visible < 0 -> 0.
pub fn str_obfuscate(s: Str, visible: Int) -> Str {
  var v = visible;
  if v < 0 { v = 0; }
  var len = str_len(s);
  var keep = v;
  if keep > len { keep = len; }
  var result = str_slice(s, 0, keep);
  var i: Int = keep;
  while i < len {
    result = str_concat(result, "*");
    i = i + 1;
  }
  return result;
}
