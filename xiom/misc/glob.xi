// XIOM - Misc: Glob Matching
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.misc.glob

// Depends on: xiom.string

// ============================================================================
// Glob pattern matching, compiling, escaping and regex translation.
// Supports the classic metacharacters: '*' (any run), '?' (any single char).
// ============================================================================

extern "C" {
    fn malloc(size: UInt) -> *UInt8;
}

/// True if ch is a glob metacharacter.
fn glob_is_magic_char(c: Char) -> Bool {
  var v = c as Int;
  v == 42 || v == 63 || v == 91
}

/// Match s against a glob pattern supporting '?' (any single character) and
/// '*' (zero or more characters). O(pattern.len() * s.len()) worst, with the
/// classic star-backtracking algorithm. Pattern matching is case-sensitive.
pub fn glob_match(pattern: Str, s: Str) -> Bool {
  var plen = pattern.len();
  var slen = s.len();
  var pi = 0;
  var si = 0;
  var star_idx = -1;
  var match_idx = 0;
  while si < slen {
    if pi < plen && pattern.char_at(pi) == '*' {
      star_idx = pi;
      match_idx = si;
      pi = pi + 1;
    } elif pi < plen && (pattern.char_at(pi) == '?' || pattern.char_at(pi) == s.char_at(si)) {
      pi = pi + 1;
      si = si + 1;
    } elif star_idx >= 0 {
      pi = star_idx + 1;
      match_idx = match_idx + 1;
      si = match_idx;
    } else {
      return false;
    }
  }
  while pi < plen && pattern.char_at(pi) == '*' {
    pi = pi + 1;
  }
  pi == plen
}

/// Case-insensitive glob match: same semantics as glob_match but compares
/// characters with case folding. O(pattern.len() * s.len()) worst.
pub fn glob_match_case_insensitive(pattern: Str, s: Str) -> Bool {
  var plen = pattern.len();
  var slen = s.len();
  var pi = 0;
  var si = 0;
  var star_idx = -1;
  var match_idx = 0;
  while si < slen {
    if pi < plen && (pattern.char_at(pi) as Int) == 92 && pi + 1 < plen {
      if to_lower(pattern.char_at(pi + 1)) == to_lower(s.char_at(si)) {
        pi = pi + 2;
        si = si + 1;
      } elif star_idx >= 0 {
        pi = star_idx + 1;
        match_idx = match_idx + 1;
        si = match_idx;
      } else {
        return false;
      }
    } elif pi < plen && pattern.char_at(pi) == '*' {
      star_idx = pi;
      match_idx = si;
      pi = pi + 1;
    } elif pi < plen {
      var pc = pattern.char_at(pi);
      var sc = s.char_at(si);
      if pc == '?' || to_lower(pc) == to_lower(sc) {
        pi = pi + 1;
        si = si + 1;
      } elif star_idx >= 0 {
        pi = star_idx + 1;
        match_idx = match_idx + 1;
        si = match_idx;
      } else {
        return false;
      }
    } elif star_idx >= 0 {
      pi = star_idx + 1;
      match_idx = match_idx + 1;
      si = match_idx;
    } else {
      return false;
    }
  }
  while pi < plen && pattern.char_at(pi) == '*' {
    pi = pi + 1;
  }
  pi == plen
}

/// Lowercase a single character via the built-in classification.
fn to_lower(c: Char) -> Char {
  var v = c as Int;
  if v >= 65 && v <= 90 {
    (v + 32) as Char
  } else {
    c
  }
}

/// Escape glob metacharacters ('*', '?', '[') in s with a backslash so the
/// result matches literally. O(len).
pub fn glob_escape(s: Str) -> Str {
  var len = s.len();
  var extra = 0;
  var i = 0;
  while i < len {
    if glob_is_magic_char(s.char_at(i)) {
      extra = extra + 1;
    }
    i = i + 1;
  }
  if extra == 0 {
    return s;
  }
  unsafe {
    var buf = malloc((len + extra) as UInt + 1);
    var out = 0;
    i = 0;
    while i < len {
      var c = s.char_at(i);
      if glob_is_magic_char(c) {
        buf[out] = 92;
        out = out + 1;
      }
      buf[out] = c as UInt8;
      out = out + 1;
      i = i + 1;
    }
    buf[out] = 0;
    return Str.from_cstring(buf);
  }
}

/// Undo glob escaping: remove one backslash before each metacharacter. O(len).
pub fn glob_unescape(s: Str) -> Str {
  var len = s.len();
  if len == 0 {
    return s;
  }
  unsafe {
    var buf = malloc((len + 1) as UInt);
    var out = 0;
    var i = 0;
    while i < len {
      var c = s.char_at(i);
      if (c as Int) == 92 && i + 1 < len {
        var next = s.char_at(i + 1);
        if glob_is_magic_char(next) {
          buf[out] = next as UInt8;
          out = out + 1;
          i = i + 2;
        } else {
          buf[out] = 92;
          out = out + 1;
          i = i + 1;
        }
      } else {
        buf[out] = c as UInt8;
        out = out + 1;
        i = i + 1;
      }
    }
    buf[out] = 0;
    return Str.from_cstring(buf);
  }
}

/// Whether s contains any glob metacharacter ('*', '?', '['). O(len).
pub fn glob_has_magic(s: Str) -> Bool {
  var i = 0;
  while i < s.len() {
    if glob_is_magic_char(s.char_at(i)) {
      return true;
    }
    i = i + 1;
  }
  false
}

/// Quote s so it matches literally: the same as glob_escape. O(len).
pub fn glob_quote(s: Str) -> Str {
  glob_escape(s)
}

/// Convert a glob pattern to a regex pattern string: '*' becomes '.*',
/// '?' becomes '.', and other regex metacharacters are escaped. O(len).
pub fn glob_translate(pattern: Str) -> Str {
  var len = pattern.len();
  var size = 0;
  var i = 0;
  while i < len {
    var c = pattern.char_at(i);
    if c == '*' {
      size = size + 2;
    } elif c == '?' {
      size = size + 1;
    } else {
      var v = c as Int;
      if v == 46 || v == 43 || v == 94 || v == 36 || v == 40 || v == 41 ||
         v == 91 || v == 93 || v == 123 || v == 125 || v == 124 || v == 92 {
        size = size + 2;
      } else {
        size = size + 1;
      }
    }
    i = i + 1;
  }
  unsafe {
    var buf = malloc((size + 1) as UInt);
    var out = 0;
    i = 0;
    while i < len {
      var c = pattern.char_at(i);
      if c == '*' {
        buf[out] = 46;
        buf[out + 1] = 42;
        out = out + 2;
      } elif c == '?' {
        buf[out] = 46;
        out = out + 1;
      } else {
        var v = c as Int;
        if v == 46 || v == 43 || v == 94 || v == 36 || v == 40 || v == 41 ||
           v == 91 || v == 93 || v == 123 || v == 125 || v == 124 || v == 92 {
          buf[out] = 92;
          out = out + 1;
        }
        buf[out] = c as UInt8;
        out = out + 1;
      }
      i = i + 1;
    }
    buf[out] = 0;
    return Str.from_cstring(buf);
  }
}

// fn glob_compile(pattern) -> Result[Int, Str] - compile a pattern to a
// matcher handle.
// fn glob_compile_match(compiled: Int, s) -> Bool - match s against a compiled
// pattern.
// NOT IMPLEMENTABLE: a matcher "handle" is a bare Int, so the original
// pattern cannot be recovered to match against; a pattern registry does not
// exist in the stdlib. Kept comment-only.
