// XIOM - Regex: Engine
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.regex.engine

// Depends on: xiom.string

use xiom.string;

// ============================================================================
// Compiled regex matching engine: match, find, capture, replace, split.
// ============================================================================
//
// Supported pattern syntax (deliberately compact, pure-XIOM backtracking):
//   .        -- matches any single character (except newline)
//   *        -- zero or more of preceding element (greedy)
//   +        -- one or more of preceding element (greedy)
//   ?        -- zero or one of preceding element (greedy)
//   ^        -- start-of-string anchor
//   $        -- end-of-string anchor
//   [abc]    -- character class (literal chars)
//   [a-z]    -- character range inside a class
//   [^abc]   -- negated character class
//   \d \w \s -- digit, word, whitespace shorthands
//   \D \W \S -- negated shorthands
//   \c       -- any other escaped character matches the literal char
//
// NOT supported (honestly): alternation `|`, groups `(...)`, backreferences,
// lookahead/lookbehind, non-greedy quantifiers, named captures, Unicode
// categories. The engine operates on bytes (via string.char_at, which is
// byte-indexed), so patterns and subjects are effectively ASCII/UTF-8
// byte-oriented.

/// A compiled regular expression: the validated pattern text and a handle.
/// `compiled` is reserved for future native backends and is always 0 here.
pub type Regex = {
  pattern: Str;
  compiled: Int;
} derive[Clone]

/// A match: half-open byte range [start, end) and the matched text.
pub type Match = {
  start: Int;
  end: Int;
  text: Str;
} derive[Eq, Clone]

/// True when `c` is a regex metacharacter (needs escaping to match literally).
fn is_metachar(c: Char) -> Bool {
  c == '.' || c == '*' || c == '+' || c == '?' || c == '^' || c == '$' || c == '[' || c == ']' || c == '\\' || c == '(' || c == ')' || c == '|' || c == '{' || c == '}'
}

/// True when `c` is an ASCII digit 0-9.
fn is_digit_char(c: Char) -> Bool {
  c >= '0' && c <= '9'
}

/// True when `c` is an ASCII word character (alphanumeric or underscore).
fn is_word_char(c: Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_'
}

/// True when `c` is a whitespace character (space, tab, LF, CR).
fn is_space_char(c: Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

/// Find the byte index of the closing ']' of a class that starts at `start`.
/// Returns `start` (no movement) if the class is unterminated.
fn class_end(pattern: Str, start: Int) -> Int {
  var pos = start + 1;
  while pos < pattern.len() {
    let pc = string.char_at(pattern, pos).unwrap();
    if pc == ']' {
      return pos;
    };
    if pc == '\\' && pos + 1 < pattern.len() {
      pos = pos + 1;
    };
    pos = pos + 1;
  };
  start
}

/// True when `ch` matches the character class starting at `start` in `pattern`.
/// Handles negation (`[^...]`), ranges (`a-z`) and `\d \w \s \D \W \S` escapes.
fn class_matches(start: Int, pattern: Str, ch: Char) -> Bool {
  var negated = false;
  var pos = start + 1;
  if pos < pattern.len() && string.char_at(pattern, pos).unwrap() == '^' {
    negated = true;
    pos = pos + 1;
  };
  var matched = false;
  while pos < pattern.len() {
    let pc = string.char_at(pattern, pos).unwrap();
    if pc == ']' {
      break;
    };
    if pos + 2 < pattern.len() && string.char_at(pattern, pos + 1).unwrap() == '-' && string.char_at(pattern, pos + 2).unwrap() != ']' {
      let range_start = pc;
      let range_end = string.char_at(pattern, pos + 2).unwrap();
      if ch >= range_start && ch <= range_end {
        matched = true;
      };
      pos = pos + 3;
    } elif pc == '\\' && pos + 1 < pattern.len() {
      let esc = string.char_at(pattern, pos + 1).unwrap();
      var esc_matched = false;
      if esc == 'd' {
        esc_matched = is_digit_char(ch);
      } elif esc == 'w' {
        esc_matched = is_word_char(ch);
      } elif esc == 's' {
        esc_matched = is_space_char(ch);
      } elif esc == 'D' {
        esc_matched = !is_digit_char(ch);
      } elif esc == 'W' {
        esc_matched = !is_word_char(ch);
      } elif esc == 'S' {
        esc_matched = !is_space_char(ch);
      } else {
        esc_matched = esc == ch;
      };
      if esc_matched {
        matched = true;
      };
      pos = pos + 2;
    } else {
      if pc == ch {
        matched = true;
      };
      pos = pos + 1;
    };
  };
  if negated { !matched } else { matched }
}

/// True when the single pattern element at `p_pos` matches `text[t_pos]`.
/// `t_pos` must be within bounds (checked by callers/quantifier logic).
fn element_matches(pattern: Str, p_pos: Int, text: Str, t_pos: Int) -> Bool {
  if t_pos >= text.len() {
    return false;
  };
  let pc = string.char_at(pattern, p_pos).unwrap();
  let tc = string.char_at(text, t_pos).unwrap();
  if pc == '.' {
    return tc != '\n';
  };
  if pc == '[' {
    return class_matches(p_pos, pattern, tc);
  };
  if pc == '\\' {
    if p_pos + 1 >= pattern.len() {
      return false;
    };
    let esc = string.char_at(pattern, p_pos + 1).unwrap();
    if esc == 'd' {
      return is_digit_char(tc);
    } elif esc == 'w' {
      return is_word_char(tc);
    } elif esc == 's' {
      return is_space_char(tc);
    } elif esc == 'D' {
      return !is_digit_char(tc);
    } elif esc == 'W' {
      return !is_word_char(tc);
    } elif esc == 'S' {
      return !is_space_char(tc);
    } else {
      return esc == tc;
    };
  };
  pc == tc
}

/// Backtracking matcher: attempt to match `pattern[p_pos..]` against
/// `text[t_pos..]`. Returns the end byte index on success, None on failure.
fn match_here(pattern: Str, text: Str, p_pos: Int, t_pos: Int) -> Option[Int] {
  let p_len = pattern.len();
  if p_pos >= p_len {
    return Some(t_pos);
  };
  let pc = string.char_at(pattern, p_pos).unwrap();
  if pc == '$' && p_pos + 1 >= p_len {
    if t_pos >= text.len() {
      return Some(t_pos);
    };
    return None;
  };
  var elem_end_raw = p_pos;
  if pc == '[' {
    elem_end_raw = class_end(pattern, p_pos) + 1;
  } elif pc == '\\' {
    if p_pos + 1 >= p_len {
      return None;
    };
    elem_end_raw = p_pos + 2;
  } else {
    elem_end_raw = p_pos + 1;
  };
  var elem_end = elem_end_raw;
  var quant = ' ';
  if elem_end_raw < p_len {
    let qc = string.char_at(pattern, elem_end_raw).unwrap();
    if qc == '*' || qc == '+' || qc == '?' {
      quant = qc;
      elem_end = elem_end_raw + 1;
    };
  };
  if quant == '*' {
    var max_t = t_pos;
    while max_t < text.len() && element_matches(pattern, p_pos, text, max_t) {
      max_t = max_t + 1;
    };
    var t = max_t;
    while t >= t_pos {
      let after = match_here(pattern, text, elem_end, t);
      if after.is_some {
        return after;
      };
      t = t - 1;
    };
    return None;
  };
  if quant == '+' {
    var max_t = t_pos;
    while max_t < text.len() && element_matches(pattern, p_pos, text, max_t) {
      max_t = max_t + 1;
    };
    if max_t == t_pos {
      return None;
    };
    var t = max_t;
    while t > t_pos {
      let after = match_here(pattern, text, elem_end, t);
      if after.is_some {
        return after;
      };
      t = t - 1;
    };
    return None;
  };
  if quant == '?' {
    let after = match_here(pattern, text, elem_end, t_pos);
    if after.is_some {
      return after;
    };
    if t_pos < text.len() && element_matches(pattern, p_pos, text, t_pos) {
      return match_here(pattern, text, elem_end, t_pos + 1);
    };
    return None;
  };
  if t_pos >= text.len() {
    return None;
  };
  if element_matches(pattern, p_pos, text, t_pos) {
    return match_here(pattern, text, elem_end, t_pos + 1);
  };
  None
}

/// Find the first match of `pattern` in `text`, honouring a leading `^` anchor.
fn find_first_match(pattern: Str, text: Str) -> Option[Match] {
  let t_len = text.len();
  if pattern.len() > 0 && string.char_at(pattern, 0).unwrap() == '^' {
    let result = match_here(pattern, text, 1, 0);
    match result {
      Some(end) => {
        let matched = string.str_slice(text, 0, end);
        return Some(Match{ start: 0; end: end; text: matched; });
      };
      None => {};
    };
    return None;
  };
  var pos: Int = 0;
  while pos <= t_len {
    let result = match_here(pattern, text, 0, pos);
    match result {
      Some(end) => {
        let matched = string.str_slice(text, pos, end);
        return Some(Match{ start: pos; end: end; text: matched; });
      };
      None => {};
    };
    pos = pos + 1;
  };
  None
}

/// True when `pattern` is syntactically valid: balanced classes and no
/// dangling escape or leading quantifier.
fn is_valid_regex(pattern: Str) -> Bool {
  var i: Int = 0;
  var bracket_depth: Int = 0;
  let p_len = pattern.len();
  while i < p_len {
    let c = string.char_at(pattern, i).unwrap();
    if c == '[' {
      bracket_depth = bracket_depth + 1;
    } elif c == ']' {
      if bracket_depth == 0 {
        return false;
      };
      bracket_depth = bracket_depth - 1;
    } elif c == '\\' {
      i = i + 1;
      if i >= p_len {
        return false;
      };
    } elif c == '*' || c == '+' || c == '?' {
      if i == 0 {
        return false;
      };
    };
    i = i + 1;
  };
  bracket_depth == 0
}

/// Compile a regex pattern. Validates the syntax and returns a compiled
/// `Regex`, or `Err` describing the problem on invalid syntax.
/// Complexity: O(len(pattern)) validation.
pub fn regex_compile(pattern: Str) -> Result[Regex, Str] {
  if !is_valid_regex(pattern) {
    return Err("invalid regex pattern");
  };
  Ok(Regex{ pattern: pattern; compiled: 0; })
}

/// True when `r` matches the entire string `s` (anchored at both ends).
/// Complexity: O(len(s) * len(r)) worst case for the backtracking matcher.
pub fn regex_match(r: Regex, s: Str) -> Bool {
  let pattern = r.pattern;
  let anchored = pattern.len() > 0 && string.char_at(pattern, 0).unwrap() == '^';
  let result = match_here(pattern, s, if anchored { 1 } else { 0 }, 0);
  match result {
    Some(end) => {
      if end == s.len() {
        return true;
      };
      false
    };
    None => false;
  }
}

/// Find the first match of `r` in `s`, or None when there is no match.
/// Complexity: O(len(s) * len(r)) worst case.
pub fn regex_find(r: Regex, s: Str) -> Option[Match] {
  find_first_match(r.pattern, s)
}

/// Find every non-overlapping match of `r` in `s`, in left-to-right order.
/// An empty pattern matches at every byte boundary.
/// Complexity: O(len(s) * len(r)) per match.
pub fn regex_find_all(r: Regex, s: Str) -> Vec[Match] {
  var matches = Vec[Match].new();
  let pattern = r.pattern;
  let t_len = s.len();
  if pattern.len() == 0 {
    var pos: Int = 0;
    while pos <= t_len {
      matches.push(Match{ start: pos; end: pos; text: ""; });
      pos = pos + 1;
    };
    return matches;
  };
  let anchored = string.char_at(pattern, 0).unwrap() == '^';
  var pos: Int = 0;
  while pos <= t_len {
    let result = match_here(pattern, s, if anchored { 1 } else { 0 }, pos);
    match result {
      Some(end) => {
        let matched = string.str_slice(s, pos, end);
        matches.push(Match{ start: pos; end: end; text: matched; });
        if end > pos {
          pos = end;
        } else {
          pos = pos + 1;
        };
        if anchored {
          pos = t_len + 1;
        };
      };
      None => {
        pos = pos + 1;
      };
    };
  };
  matches
}

/// Capture groups of the first match of `r` in `s`. This engine has no group
/// syntax, so the returned vector contains exactly one element: the full
/// match text (group 0). None when there is no match.
/// Complexity: O(len(s) * len(r)) worst case.
pub fn regex_captures(r: Regex, s: Str) -> Option[Vec[Str]] {
  let m = find_first_match(r.pattern, s);
  var groups = Vec[Str].new();
  match m {
    Some(match_obj) => {
      groups.push(match_obj.text);
    };
    None => {};
  };
  if m.is_some {
    return Option[Vec[Str]]{ is_some: true; value: groups; };
  };
  Option[Vec[Str]]{ is_some: false; value: groups; }
}

/// Names of the named capture groups. This engine has no named-group syntax,
/// so the result is always an empty vector.
/// Complexity: O(1).
pub fn regex_capture_names(r: Regex) -> Vec[Str] {
  Vec[Str].new()
}

/// Convenience: compile `pattern` then search `s` for any match (find
/// semantics, like PCRE `pcre_exec`). Returns false on invalid pattern
/// syntax or when there is no match.
/// Complexity: O(len(s) * len(pattern)) worst case.
pub fn regex_is_match(pattern: Str, s: Str) -> Bool {
  let compiled = regex_compile(pattern);
  match compiled {
    Ok(r) => find_first_match(r.pattern, s).is_some;
    Err(_) => false;
  }
}

/// Convenience: compile `pattern` then find all matches in `s`.
/// Returns an empty vector on invalid pattern syntax.
/// Complexity: O(len(s) * len(pattern)) worst case.
pub fn regex_matches(pattern: Str, s: Str) -> Vec[Match] {
  let compiled = regex_compile(pattern);
  match compiled {
    Ok(r) => regex_find_all(r, s);
    Err(_) => Vec[Match].new();
  }
}

/// Replace the first match of `r` in `s` with `replacement`.
/// Returns `s` unchanged when there is no match. Literal replacement (no $1).
/// Complexity: O(len(s) + len(replacement)).
pub fn regex_replace(r: Regex, s: Str, replacement: Str) -> Str {
  let m = find_first_match(r.pattern, s);
  match m {
    Some(match_obj) => {
      let before = string.str_slice(s, 0, match_obj.start);
      let after = string.str_slice(s, match_obj.end, s.len());
      string.str_concat(string.str_concat(before, replacement), after)
    };
    None => s;
  }
}

/// Replace every non-overlapping match of `r` in `s` with `replacement`.
/// Returns `s` unchanged when there are no matches. Literal replacement.
/// Complexity: O(len(s) + matches * len(replacement)).
pub fn regex_replace_all(r: Regex, s: Str, replacement: Str) -> Str {
  let matches = regex_find_all(r, s);
  if matches.len() == 0 {
    return s;
  };
  var result = "";
  var pos: Int = 0;
  var i: Int = 0;
  while i < matches.len() {
    result = string.str_concat(result, string.str_slice(s, pos, matches[i].start));
    result = string.str_concat(result, replacement);
    pos = matches[i].end;
    i = i + 1;
  };
  string.str_concat(result, string.str_slice(s, pos, s.len()))
}

/// Split `s` around every non-overlapping match of `r`. An empty pattern
/// splits into individual characters. The trailing segment is always present.
/// Complexity: O(len(s) * len(r)) worst case.
pub fn regex_split(r: Regex, s: Str) -> Vec[Str] {
  var result = Vec[Str].new();
  let pattern = r.pattern;
  let t_len = s.len();
  if pattern.len() == 0 {
    var pos: Int = 0;
    while pos < t_len {
      result.push(string.str_slice(s, pos, pos + 1));
      pos = pos + 1;
    };
    return result;
  };
  var seg_start: Int = 0;
  var pos: Int = 0;
  while pos <= t_len {
    let match_result = match_here(pattern, s, 0, pos);
    match match_result {
      Some(end) => {
        result.push(string.str_slice(s, seg_start, pos));
        if end > pos {
          pos = end;
        } else {
          pos = pos + 1;
        };
        seg_start = pos;
      };
      None => {
        pos = pos + 1;
      };
    };
  };
  result.push(string.str_slice(s, seg_start, t_len));
  result
}

/// Lazily-ordered iterator of every match of `r` in `s`, materialised as a
/// vector in left-to-right order. Equivalent to `regex_find_all`.
/// Complexity: O(len(s) * len(r)) worst case.
pub fn regex_find_iter(r: Regex, s: Str) -> Vec[Match] {
  regex_find_all(r, s)
}
