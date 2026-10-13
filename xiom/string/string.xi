// XIOM -- String Library
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  // asm-accelerated with a C fallback in the runtime; always links.
  fn xiom_memcpy_dispatch(dest: *UInt8, src: *UInt8, n: UInt) -> *UInt8;
  fn xiom_char_at(s: Str, pos: Int) -> Char;
  // round-14 (BUG 26 #7): the RAW BYTE accessor -- xiom_char_at now
  // returns the decoded UTF-8 CODEPOINT, which broke byte_at (the old
  // byte_at reused xiom_char_at and double-decoded multibyte strings).
  // Declared Int (i64) -- the runtime's return -- the wrapper casts.
  fn xiom_byte_at(s: Str, pos: Int) -> Int;
}

// Wave 111 (xvector REL-20261011-1453): raw byte access over a cached
// (base, len) view for slice copies. byte_at re-scans the whole string per
// call (runtime strnlen), so byte-stepped copies were O(k*n) -- the json
// parser's per-token slices and slice.str_bytes were the observed quadratic
// paths. Callers bound i against the cached length.
fn _raw_byte(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

// Slice [start, end) over a cached pointer WITHOUT the str_len clamp
// (wave 129): str_slice rescans the source per call (strlen), so per-part /
// per-character slices were O(|s|) each. Callers guarantee
// 0 <= start <= end <= len, which makes the result identical to str_slice.
// Complexity: O(end - start).
fn _slice_fast(base: *UInt8, start: Int, end: Int) -> Str
  requires: true  // raw byte copy; callers bound the range (T007)
{
  let n = end - start;
  unsafe {
    var buf = malloc(n + 1);
    var i: Int = 0;
    while i < n {
      buf[i] = _raw_byte(base, start + i);
      i = i + 1;
    };
    buf[n] = 0;
    return Str.from_cstring(buf);
  }
}

// Wave 126: runtime-`xiom_char_at`-equivalent UTF-8 decode over a cached
// (base, len) view (copied byte-exact from slice.xi). char_at re-scans the
// whole string per call (runtime strnlen), so the per-position decodes in
// the character loops below were quadratic. Continuation bytes are
// validated, a malformed or truncated sequence yields the leading byte
// itself, and a stray continuation byte is returned as-is. Out-of-range
// positions read as 0 (the NUL byte the runtime would see).
// Complexity: O(1).
fn _char_at_runtime(base: *UInt8, len: Int, pos: Int) -> Char {
  if pos < 0 || pos >= len {
    return to_char(0);
  }
  var b0 = (_raw_byte(base, pos) as Int) & 0xFF;
  if b0 < 0x80 {
    return to_char(b0);
  }
  var n = 0;
  var cp = 0;
  if (b0 & 0xE0) == 0xC0 {
    n = 2;
    cp = b0 & 0x1F;
  } elif (b0 & 0xF0) == 0xE0 {
    n = 3;
    cp = b0 & 0x0F;
  } elif (b0 & 0xF8) == 0xF0 {
    n = 4;
    cp = b0 & 0x07;
  } else {
    return to_char(b0);
  }
  var i = 1;
  while i < n {
    var cb = 0;
    if pos + i < len {
      cb = (_raw_byte(base, pos + i) as Int) & 0xFF;
    }
    if (cb & 0xC0) != 0x80 {
      return to_char(b0);
    }
    cp = (cp << 6) | (cb & 0x3F);
    i = i + 1;
  }
  return to_char(cp);
}

/// Byte length of the string.
pub fn str_len(s: Str) -> Int
  ensures: result >= 0
{
  s.len()
}

/// Concatenation of two strings.
pub fn str_concat(a: Str, b: Str) -> Str
  ensures: result.len() == a.len() + b.len()
{
  let len_a = a.len();
  let len_b = b.len();
  let total = len_a + len_b;
  unsafe {
    var buf = malloc(total + 1);
    // Bulk copy via the runtime's asm/C memcpy (phase E3 re-land). A Str IS
    // a NUL-terminated buffer pointer (see os.xi cstr precedent for the
    // cast); sources are non-overlapping regions of the fresh buffer.
    // R16: `buf + len_a` as an argument miscompiles, so the second dest
    // address is built through an Int cast.
    xiom_memcpy_dispatch(buf, a as *UInt8, len_a as UInt);
    var dst2 = (buf as Int + len_a) as *UInt8;
    xiom_memcpy_dispatch(dst2, b as *UInt8, len_b as UInt);
    buf[total] = 0;
    return Str.from_cstring(buf);
  }
}

/// Byte slice [start, end) of the string.
pub fn str_slice(s: Str, start: Int, end: Int) -> Str
  ensures: end >= start && start >= 0 && end <= s.len() => result.len() == end - start
  ensures: result.len() <= s.len()
{
  let len = s.len();
  var s_start = start;
  var s_end = end;
  if s_start < 0 { s_start = 0; };
  if s_end > len { s_end = len; };
  if s_start >= s_end { return ""; };
  let slice_len = s_end - s_start;
  let base = s.c_str();
  unsafe {
    var buf = malloc(slice_len + 1);
    var i: Int = 0;
    while i < slice_len {
      buf[i] = _raw_byte(base, s_start + i);
      i = i + 1;
    }
    buf[slice_len] = 0;
    return Str.from_cstring(buf);
  }
}

/// True when `substr` occurs in the string.
pub fn str_contains(s: Str, substr: Str) -> Bool
  ensures: substr.len() == 0 => result
{
  let result = index_of(s, substr);
  result.is_some
}

// Byte-wise matcher: does `sub` occur at byte offset `at` of `s`?
// Allocation-free (audit 5.2 / phase E2): the previous implementations
// built a fresh slice per candidate position via str_slice.
// UTF-8-safe: valid UTF-8 is prefix/suffix closed under byte comparison,
// and byte_at returns raw bytes (round-14 semantics).
fn _matches_at(s: Str, at: Int, sub: Str) -> Bool
  requires: true  // raw byte reads over cached pointers; callers bound at (T007)
{
  let n = sub.len();
  let bs = s.c_str();
  let bsub = sub.c_str();
  var i = 0;
  while i < n {
    if _raw_byte(bs, at + i) != _raw_byte(bsub, i) {
      return false;
    };
    i = i + 1;
  };
  return true;
}

/// True when the string starts with `prefix`.
pub fn str_starts_with(s: Str, prefix: Str) -> Bool
  ensures: prefix.len() == 0 => result
{
  let prefix_len = prefix.len();
  if prefix_len > s.len() {
    return false;
  };
  _matches_at(s, 0, prefix)
}

/// True when the string ends with `suffix`.
pub fn str_ends_with(s: Str, suffix: Str) -> Bool
  ensures: suffix.len() == 0 => result
{
  let suffix_len = suffix.len();
  let s_len = s.len();
  if suffix_len > s_len {
    return false;
  };
  _matches_at(s, s_len - suffix_len, suffix)
}

/// Lexicographic byte-wise comparison of `a` and `b`: negative when `a`
/// sorts before `b`, 0 when equal, positive when after. Byte-wise over the
/// UTF-8 representation (matches Unicode code-point order for ASCII). This
/// is the canonical implementation exposed on `xiom.string` itself;
/// `xiom.string.compare.str_compare` delegates here so `use xiom.string;`
/// alone resolves the call.
pub fn str_compare(a: Str, b: Str) -> Int
  ensures: result >= -1 && result <= 1
{
  let la = a.len();
  let lb = b.len();
  let ba_base = a.c_str();
  let bb_base = b.c_str();
  var i: Int = 0;
  while i < la && i < lb {
    let ba = _raw_byte(ba_base, i) as Int;
    let bb = _raw_byte(bb_base, i) as Int;
    if ba < bb {
      return -1;
    };
    if ba > bb {
      return 1;
    };
    i = i + 1;
  };
  if la < lb {
    return -1;
  };
  if la > lb {
    return 1;
  };
  0
}

/// Split on `delimiter` into parts (empty parts preserved).
/// Byte-compare scan: O(|s| * |delimiter|), no per-position slicing
/// (ORBITDB relay 2026-10-08: the old slice-per-position scan was quadratic
/// and made 5 MB WAL replays take ~44 s).
pub fn str_split(s: Str, delimiter: Str) -> Vec[Str]
  ensures:  result.len() >= 1  // always at least one element
{
  var result = Vec[Str].new();
  let delim_len = delimiter.len();
  let s_len = s.len();
  let bs = s.c_str();
  if delim_len == 0 {
    var i: Int = 0;
    while i < s_len {
      result.push(_slice_fast(bs, i, i + 1));
      i = i + 1;
    }
    if result.len() == 0 {
      result.push("");
    }
    return result;
  };
  var start: Int = 0;
  var pos: Int = 0;
  let bd = delimiter.c_str();
  while pos < s_len {
    var is_match: Bool = false;
    if pos + delim_len <= s_len {
      is_match = true;
      var k: Int = 0;
      while k < delim_len {
        if _raw_byte(bs, pos + k) != _raw_byte(bd, k) {
          is_match = false;
          k = delim_len;
        } else {
          k = k + 1;
        };
      };
    };
    if is_match {
      result.push(_slice_fast(bs, start, pos));
      pos = pos + delim_len;
      start = pos;
    } else {
      pos = pos + 1;
    };
  }
  result.push(_slice_fast(bs, start, s_len));
  result
}

/// Copy without leading/trailing ASCII whitespace.
/// Wave 126: whitespace scan over the cached (base, len) view.
pub fn str_trim(s: Str) -> Str
  ensures: result.len() <= s.len()  // trim never increases length
{
  let len = s.len();
  let base = s.c_str();
  var start: Int = 0;
  var end: Int = len;
  while start < len && xiom.char.is_whitespace(_char_at_runtime(base, len, start)) {
    start = start + 1;
  }
  while end > start && xiom.char.is_whitespace(_char_at_runtime(base, len, end - 1)) {
    end = end - 1;
  }
  str_slice(s, start, end)
}

/// Parse an Int; Err with a message on bad input.
pub fn str_to_int(s: Str) -> Result[Int, Str]
{
  xiom.core.to_int_from_str(s)
}

/// Parse a Float64; Err with a message on bad input.
pub fn str_to_float(s: Str) -> Result[Float64, Str]
{
  xiom.core.to_float_from_str(s)
}

/// Copy with lowercase letters uppercased.
pub fn str_upper(s: Str) -> Str
  ensures: result.len() == s.len()
{
  // Byte-safe: ASCII a-z -> A-Z; all other bytes (incl. UTF-8 sequences)
  // pass through verbatim. The char-based version truncated multibyte
  // chars to their low byte (xiom_char_at -> as UInt8).
  let len = s.len();
  let base = s.c_str();
  unsafe {
    var buf = malloc(len + 1);
    var i: Int = 0;
    while i < len {
      let b = _raw_byte(base, i);
      if b >= 97 && b <= 122 {
        buf[i] = (b - 32) as UInt8;
      } else {
        buf[i] = b;
      };
      i = i + 1;
    }
    buf[len] = 0;
    return Str.from_cstring(buf);
  }
}

/// Copy with uppercase letters lowercased.
pub fn str_lower(s: Str) -> Str
  ensures: result.len() == s.len()
{
  // Byte-safe: ASCII A-Z -> a-z; all other bytes pass through verbatim.
  let len = s.len();
  let base = s.c_str();
  unsafe {
    var buf = malloc(len + 1);
    var i: Int = 0;
    while i < len {
      let b = _raw_byte(base, i);
      if b >= 65 && b <= 90 {
        buf[i] = (b + 32) as UInt8;
      } else {
        buf[i] = b;
      };
      i = i + 1;
    }
    buf[len] = 0;
    return Str.from_cstring(buf);
  }
}

/// Return `fmt` unchanged (formatting with no arguments).
pub fn format(fmt: Str) -> Str {
  fmt
}

/// Substitute the first `{}` placeholder with `arg`.
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

/// Substitute the first two `{}` placeholders with the arguments.
pub fn format2(fmt: Str, arg1: Str, arg2: Str) -> Str {
  let s = format1(fmt, arg1);
  format1(s, arg2)
}

/// Byte value at `pos`, or 0 when out of bounds.
pub fn byte_at(s: Str, pos: Int) -> UInt8
  requires: true  // extern byte accessor confined below (T002/T007)
{
  unsafe {
    return (xiom_byte_at(s, pos)) as UInt8;
  }
}

/// UTF-8 character at byte position `pos`, or None.
pub fn char_at(s: Str, pos: Int) -> Option[Char]
  // char_at indexes BYTE positions (like byte_at); contracts mirror the body
  // guard. Restored after the R8 contract-codegen fix (20aa3d07): the old
  // `s.char_count()` clause evaluated 0 inside contracts (aborting every
  // Some), and the first byte-domain rewrite crashed method-position calls
  // before that fix landed.
  ensures: result is Some => pos >= 0 && pos < s.len()
  ensures: result is None => pos < 0 || pos >= s.len()
{
  if pos < 0 || pos >= s.len() {
    return None;
  };
  Some(xiom_char_at(s, pos))
}

/// Byte index of the first occurrence, or None.
pub fn index_of(s: Str, substr: Str) -> Option[Int]
  ensures: substr.len() == 0 => result.is_some
  ensures: result is Some => result >= 0 && result <= s.len()
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
    if _matches_at(s, i, substr) {
      return Some(i);
    };
    i = i + 1;
  };
  None
}

/// Byte index of the last occurrence, or None.
pub fn last_index_of(s: Str, substr: Str) -> Option[Int]
  ensures: result is Some => result >= 0 && result <= s.len()
{
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
    if _matches_at(s, i, substr) {
      return Some(i);
    };
    i = i - 1;
  };
  None
}

/// Replace all occurrences of `from` with `to`.
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

/// Lines split on newlines (terminators removed).
pub fn lines(s: Str) -> Vec[Str]
  ensures: result.len() >= 1
{
  str_split(s, "\n")
}

/// Whitespace-separated words.
/// Wave 126: whitespace scan over the cached (base, len) view.
pub fn words(s: Str) -> Vec[Str]
  requires: true  // cached raw-view decode in the loops (T002 confinement)
{
  var result = Vec[Str].new();
  let len = s.len();
  let base = s.c_str();
  var i: Int = 0;
  while i < len {
    while i < len && xiom.char.is_whitespace(_char_at_runtime(base, len, i)) {
      i = i + 1;
    }
    if i < len {
      var start = i;
      while i < len && !xiom.char.is_whitespace(_char_at_runtime(base, len, i)) {
        i = i + 1;
      }
      result.push(_slice_fast(base, start, i));
    };
  }
  result
}

/// True when the string has zero bytes.
pub fn is_empty(s: Str) -> Bool
  ensures: result == (s.len() == 0)
{
  s.len() == 0
}

/// Method form: `x.is_empty()`. The plain fn above is NOT a method -- the
/// compiler's receiver-typed method lookup needs the Str receiver decl
/// (method-form `x.is_empty()` otherwise falls through to a Vec/array
/// is_empty leaf or a stub and always returns false).
pub fn Str.is_empty(self) -> Bool
  ensures: result == (self.len() == 0)
{
  self.len() == 0
}

/// Number of UTF-8 characters.
/// Wave 126: boundary walk over the cached (base, len) view.
pub fn char_count(s: Str) -> Int
  ensures: result >= 0
{
  var count: Int = 0;
  let len = s.len();
  let base = s.c_str();
  var i: Int = 0;
  while i < len {
    let c = _char_at_runtime(base, len, i);
    let byte_len = xiom.char.len_utf8(c);
    i = i + byte_len;
    count = count + 1;
  }
  count
}

/// Number of bytes.
pub fn byte_count(s: Str) -> Int
  ensures: result >= 0
{
  s.len()
}

// --------------------------------------------------
//  Extended String Functions
// --------------------------------------------------

// -- Search --

/// Returns the first byte index of needle in haystack, or None if not found.
/// O(n*m) naive search. For an empty needle, returns Some(0).
pub fn str_index_of(haystack: Str, needle: Str) -> Option[Int]
  ensures: needle.len() == 0 => result.is_some
{
  index_of(haystack, needle)
}

/// Returns the last byte index of needle in haystack, or None if not found.
/// O(n*m) reverse naive search. For an empty needle, returns Some(haystack.len()).
pub fn str_rindex_of(haystack: Str, needle: Str) -> Option[Int]
  ensures: result is Some => result >= 0 && result <= haystack.len()
{
  last_index_of(haystack, needle)
}

// -- Replace --

/// Replaces every occurrence of `from` with `to` in `s`.
/// O(n*m) where n = |s|, m = |from|. If `from` is empty, returns `s` unchanged.
pub fn str_replace_all(s: Str, from_needle: Str, to_replacement: Str) -> Str
  ensures: from_needle.len() == 0 => result.len() == s.len()
{
  replace(s, from_needle, to_replacement)
}

// -- Repeat & Pad --

/// Repeats `s` `n` times. Returns empty string if n <= 0.
/// Doubling build: O(n * |s|) total copying (was quadratic accumulation).
pub fn str_repeat(s: Str, n: Int) -> Str
  ensures: n <= 0 => result.len() == 0
  ensures: n >= 0 => result.len() == s.len() * n
{
  if n <= 0 {
    return "";
  };
  var result = "";
  var chunk = s;
  var remaining = n;
  while remaining > 0 {
    if remaining % 2 == 1 {
      result = str_concat(result, chunk);
    };
    remaining = remaining / 2;
    if remaining > 0 {
      chunk = str_concat(chunk, chunk);
    };
  };
  result
}

/// Left-pads `s` with `pad` until the string reaches `width` bytes.
/// If `s` is already >= `width` in bytes, returns `s` unchanged.
/// O(width - |s|); single-byte pad characters only (one small allocation,
/// not one per pad byte as before).
pub fn str_pad_left(s: Str, width: Int, pad: Char) -> Str
  ensures: result.len() >= s.len()
{
  let s_len = s.len();
  if s_len >= width {
    return s;
  };
  let pad_len = width - s_len;
  var one = "";
  unsafe {
    var buf = malloc(2);
    buf[0] = pad as UInt8;
    buf[1] = 0;
    one = Str.from_cstring(buf);
  };
  let pad_str = str_repeat(one, pad_len);
  str_concat(pad_str, s)
}

/// Right-pads `s` with `pad` until the string reaches `width` bytes.
/// If `s` is already >= `width` in bytes, returns `s` unchanged.
/// O(width - |s|); single-byte pad characters only (one small allocation).
pub fn str_pad_right(s: Str, width: Int, pad: Char) -> Str
  ensures: result.len() >= s.len()
{
  let s_len = s.len();
  if s_len >= width {
    return s;
  };
  var one = "";
  unsafe {
    var buf = malloc(2);
    buf[0] = pad as UInt8;
    buf[1] = 0;
    one = Str.from_cstring(buf);
  };
  let pad_str = str_repeat(one, width - s_len);
  str_concat(s, pad_str)
}

// -- Strip --

/// If `s` starts with `prefix`, returns `Some(s without prefix)`.
/// Otherwise returns `None`.
/// O(|prefix|).
pub fn str_strip_prefix(s: Str, prefix: Str) -> Option[Str] {
  if str_starts_with(s, prefix) {
    let remaining = str_slice(s, prefix.len(), s.len());
    return Some(remaining);
  };
  None
}

/// If `s` ends with `suffix`, returns `Some(s without suffix)`.
/// Otherwise returns `None`.
/// O(|suffix|).
pub fn str_strip_suffix(s: Str, suffix: Str) -> Option[Str] {
  if str_ends_with(s, suffix) {
    let remaining = str_slice(s, 0, s.len() - suffix.len());
    return Some(remaining);
  };
  None
}

// -- Escape/Unescape --

/// Escapes special characters (\n, \t, \", \\, \r) in `s`.
/// Returns a new string with escape sequences replaced by their literal representations.
/// O(|s|). For multi-byte UTF-8 chars, only \n \t \" \\ \r are escaped.
/// Wave 126: single-Vec builder over the cached (base, len) view (the
/// previous slice/concat-per-char loop allocated O(n) strings and, because
/// strings leak by design, ~n^2/2 bytes of output buffer for large inputs).
pub fn str_escape(s: Str) -> Str
  requires: true  // cached raw-view decode in the loop (T002 confinement)
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  let len = s.len();
  let base = s.c_str();
  var i: Int = 0;
  while i < len {
    let c = _char_at_runtime(base, len, i);
    if c == '\n' {
      out.push(92);
      out.push(110);
    } elif c == '\t' {
      out.push(92);
      out.push(116);
    } elif c == '\"' {
      out.push(92);
      out.push(34);
    } elif c == '\\' {
      out.push(92);
      out.push(92);
    } elif c == '\r' {
      out.push(92);
      out.push(114);
    } else {
      let code = xiom.char.to_int_from_char(c);
      if code <= 0x7F {
        out.push(code as UInt8);
      } elif code <= 0x7FF {
        out.push((0xC0 | (code >> 6)) as UInt8);
        out.push((0x80 | (code & 0x3F)) as UInt8);
      } elif code <= 0xFFFF {
        out.push((0xE0 | (code >> 12)) as UInt8);
        out.push((0x80 | ((code >> 6) & 0x3F)) as UInt8);
        out.push((0x80 | (code & 0x3F)) as UInt8);
      } else {
        out.push((0xF0 | (code >> 18)) as UInt8);
        out.push((0x80 | ((code >> 12) & 0x3F)) as UInt8);
        out.push((0x80 | ((code >> 6) & 0x3F)) as UInt8);
        out.push((0x80 | (code & 0x3F)) as UInt8);
      };
    };
    i = i + xiom.char.len_utf8(c);
  };
  Str::from_utf8(out)
}

/// Un-escapes a string that contains escape sequences like \n \t \" \\ \r.
/// Returns the string with literal escape sequences replaced by the actual characters.
/// O(|s|). Unrecognised escape sequences are left unchanged.
/// Wave 126: single-Vec builder over the cached (base, len) view; literal
/// runs copy the raw bytes verbatim (malformed sequences included), exactly
/// like the previous str_slice-per-char path.
pub fn str_unescape(s: Str) -> Str
  requires: true  // cached raw-view decode in the loop (T002 confinement)
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  let len = s.len();
  let base = s.c_str();
  var i: Int = 0;
  while i < len {
    let c = _char_at_runtime(base, len, i);
    if c == '\\' && i + 1 < len {
      let next = _char_at_runtime(base, len, i + 1);
      if next == 'n' {
        out.push(10);
        i = i + 2;
      } elif next == 't' {
        out.push(9);
        i = i + 2;
      } elif next == '\"' {
        out.push(34);
        i = i + 2;
      } elif next == '\\' {
        out.push(92);
        i = i + 2;
      } elif next == 'r' {
        out.push(13);
        i = i + 2;
      } else {
        out.push(_raw_byte(base, i));
        i = i + 1;
      };
    } else {
      var byte_adv = xiom.char.len_utf8(c);
      var k: Int = 0;
      while k < byte_adv && i + k < len {
        out.push(_raw_byte(base, i + k));
        k = k + 1;
      };
      i = i + byte_adv;
    };
  };
  Str::from_utf8(out)
}

// -- Case --

/// Converts `s` to Title Case: first character of each space-separated word
/// is uppercased, remaining characters are lowercased.
/// O(|s|) byte-by-byte. Only handles ASCII letter case correctly.
/// Wave 126: per-byte decode over the cached (base, len) view.
pub fn str_title_case(s: Str) -> Str
  ensures: result.len() == s.len()
{
  let len = s.len();
  let base = s.c_str();
  var new_word = true;
  unsafe {
    var buf = malloc(len + 1);
    var i: Int = 0;
    while i < len {
      let c = _char_at_runtime(base, len, i);
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

/// Swaps the case of every character in `s`: uppercase becomes lowercase and
/// vice versa. Characters that are neither are left unchanged.
/// O(|s|) byte-by-byte. Only handles ASCII letter case correctly.
/// Wave 126: per-byte decode over the cached (base, len) view.
pub fn str_swap_case(s: Str) -> Str
  ensures: result.len() == s.len()
{
  let len = s.len();
  let base = s.c_str();
  unsafe {
    var buf = malloc(len + 1);
    var i: Int = 0;
    while i < len {
      let c = _char_at_runtime(base, len, i);
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

/// Returns true if `s` has zero length.
/// O(1).
pub fn str_is_empty(s: Str) -> Bool
  ensures: result == (s.len() == 0)
{
  s.len() == 0
}

// -- Reverse --

/// Reverses the characters in `s`. Unicode-aware: iterates by
/// proper UTF-8 character boundaries.
/// O(|s|) -- one boundary pass collects the code points, one build pass
/// emits them in reverse.
/// Wave 126: the previous nested boundary search re-decoded the string from
/// the front for every character (quadratic) and could not terminate on
/// malformed trailing sequences; the single pass below is byte-exact for
/// every input the old walk completed. A truncated trailing sequence (whose
/// decoded lead byte encodes longer than the bytes left in the buffer) is
/// emitted as its raw remaining bytes, so the byte length is preserved on
/// every input.
pub fn str_reverse(s: Str) -> Str
  ensures: result.len() == s.len()
{
  let len = s.len();
  if len == 0 {
    return "";
  };
  let base = s.c_str();
  var codes: Vec[Int] = Vec[Int].new();
  var total_bytes: Int = 0;
  var last_start: Int = 0;
  var i: Int = 0;
  while i < len {
    last_start = i;
    let c = _char_at_runtime(base, len, i);
    codes.push(xiom.char.to_int_from_char(c));
    let bl = xiom.char.len_utf8(c);
    total_bytes = total_bytes + bl;
    i = i + bl;
  };
  unsafe {
    var buf = malloc(total_bytes + 1);
    var out_pos: Int = 0;
    var k: Int = codes.len();
    // Truncated tail: emit its raw remaining bytes verbatim first (the
    // reversed order starts at the end of the string).
    if k > 0 && total_bytes > len {
      var j: Int = last_start;
      while j < len {
        buf[out_pos] = _raw_byte(base, j);
        out_pos = out_pos + 1;
        j = j + 1;
      };
      k = k - 1;
    };
    while k > 0 {
      k = k - 1;
      let code = codes[k];
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
    };
    buf[out_pos] = 0;
    return Str.from_cstring(buf);
  }
}

// -- Count --

/// Counts the number of Unicode characters in `s` using xiom_char_at.
/// Unicode-aware: advances by the byte length of each character.
/// O(|s|).
pub fn str_count_chars(s: Str) -> Int
  ensures: result >= 0
{
  char_count(s)
}

// -- Truncate --

/// Truncates `s` at the given byte position `max_bytes`, ensuring the result
/// does not split a multi-byte UTF-8 character. If `max_bytes` lands in the
/// middle of a multi-byte sequence, the result is truncated before that
/// character begins.
/// O(|s|). Wave 126: boundary walk over the cached (base, len) view.
pub fn str_truncate_utf8(s: Str, max_bytes: Int) -> Str
  ensures: max_bytes >= 0 => result.len() <= max_bytes
{
  let len = s.len();
  if max_bytes >= len {
    return s;
  };
  if max_bytes <= 0 {
    return "";
  };
  let base = s.c_str();
  var i: Int = 0;
  var last_valid: Int = 0;
  while i < len && i < max_bytes {
    let c = _char_at_runtime(base, len, i);
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

/// Centers `s` within a field of `width` bytes by adding spaces on both sides.
/// If an odd number of spaces are needed, the extra space goes on the right.
/// Only handles single-byte pad characters correctly.
/// O(width).
pub fn str_center(s: Str, width: Int) -> Str
  ensures: result.len() >= s.len()
{
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

/// Returns true if `s` starts with any of the given prefixes.
/// O(n * k) where n = |s|, k = prefixes.len().
pub fn str_starts_with_any(s: Str, prefixes: &Vec[Str]) -> Bool
  ensures: prefixes.len() == 0 => result == false
{
  var i: Int = 0;
  while i < prefixes.len() {
    if str_starts_with(s, prefixes[i]) {
      return true;
    };
    i = i + 1;
  };
  false
}

/// Returns true if `s` ends with any of the given suffixes.
/// O(n * k) where n = |s|, k = suffixes.len().
pub fn str_ends_with_any(s: Str, suffixes: &Vec[Str]) -> Bool
  ensures: suffixes.len() == 0 => result == false
{
  var i: Int = 0;
  while i < suffixes.len() {
    if str_ends_with(s, suffixes[i]) {
      return true;
    };
    i = i + 1;
  };
  false
}

/// Returns true if `s` contains any of the given substrings.
/// O(n * m * k) where n = |s|, m = max substring length, k = needles.len().
pub fn str_contains_any(s: Str, needles: &Vec[Str]) -> Bool
  ensures: needles.len() == 0 => result == false
{
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
// Wave 132b (audit): the last callers were replaced by direct Vec pushes in
// wave 127/129, so this helper is gone.

/// Translate characters per the `tr` utility: each char of `s` found in
/// `from` is replaced by the char at the same position in `to`; chars beyond
/// `to`'s length are REMOVED; chars not in `from` pass through. ASCII.
pub fn str_translate(s: Str, from: Str, to: Str) -> Str
  ensures: result.len() <= s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  let s_len = str_len(s);
  let from_len = str_len(from);
  let to_len = str_len(to);
  let bs = s.c_str();
  let bf = from.c_str();
  let bt = to.c_str();
  var i: Int = 0;
  while i < s_len {
    var c = _raw_byte(bs, i);
    var j: Int = 0;
    var found = false;
    while j < from_len {
      if _raw_byte(bf, j) == c {
        found = true;
        break;
      }
      j = j + 1;
    }
    if !found {
      out.push(c);
    } elif j < to_len {
      out.push(_raw_byte(bt, j));
    }
    // j >= to_len: removed
    i = i + 1;
  }
  return Str::from_utf8(out);
}

/// ROT13 over A-Z/a-z (ASCII).
pub fn str_rot13(s: Str) -> Str
  ensures: result.len() == s.len()
{
  return str_caesar(s, 13);
}

/// ROT47 over ASCII 33..126 (all printable chars rotate by 47).
pub fn str_rot47(s: Str) -> Str
  ensures: result.len() == s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  let len = str_len(s);
  let base = s.c_str();
  var i: Int = 0;
  while i < len {
    var b = _raw_byte(base, i) as Int;
    if b >= 33 && b <= 126 {
      var v = b - 33;
      v = (v + 47) % 94;
      out.push((v + 33) as UInt8);
    } else {
      out.push(_raw_byte(base, i));
    }
    i = i + 1;
  }
  return Str::from_utf8(out);
}

/// Caesar shift over A-Z/a-z (ASCII). Negative shifts go backwards; the
/// shift wraps mod 26.
pub fn str_caesar(s: Str, shift: Int) -> Str
  ensures: result.len() == s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  let len = str_len(s);
  let base = s.c_str();
  var sh = shift % 26;
  if sh < 0 { sh = sh + 26; }
  var i: Int = 0;
  while i < len {
    var b = _raw_byte(base, i) as Int;
    if b >= 97 && b <= 122 {
      var v = (b - 97 + sh) % 26 + 97;
      out.push(v as UInt8);
    } elif b >= 65 && b <= 90 {
      var v2 = (b - 65 + sh) % 26 + 65;
      out.push(v2 as UInt8);
    } else {
      out.push(_raw_byte(base, i));
    }
    i = i + 1;
  }
  return Str::from_utf8(out);
}

/// Atbash: a<->z, A<->Z mirror (ASCII). Non-letters pass through.
pub fn str_atbash(s: Str) -> Str
  ensures: result.len() == s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  let len = str_len(s);
  let base = s.c_str();
  var i: Int = 0;
  while i < len {
    var b = _raw_byte(base, i) as Int;
    if b >= 97 && b <= 122 {
      out.push((97 + (122 - b)) as UInt8);
    } elif b >= 65 && b <= 90 {
      out.push((65 + (90 - b)) as UInt8);
    } else {
      out.push(_raw_byte(base, i));
    }
    i = i + 1;
  }
  return Str::from_utf8(out);
}

/// Abbreviate with a middle ellipsis: keeps `(max_len-3)/2` chars from the
/// front and the rest from the back ("..." as "..."). Strings at or under
/// max_len are returned unchanged; max_len < 4 falls back to truncation.
pub fn str_abbreviate(s: Str, max_len: Int) -> Str
  ensures: result.len() <= s.len()
{
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
pub fn str_obfuscate(s: Str, visible: Int) -> Str
  ensures: result.len() == s.len()
{
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
