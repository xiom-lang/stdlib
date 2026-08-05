// XIOM — Regular Expressions
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.regex

use xiom.string;

pub type Regex = { pattern: Str; compiled: Int; } derive[Clone]
pub type Match = { start: Int; end: Int; text: Str; } derive[Eq, Clone]
pub type Captures = { groups: Vec[Option[Match]]; } derive[Clone]

// ── Simplified regex engine ──
// This is a simplified regex engine. Full PCRE features (lookahead,
// backreferences, non-greedy quantifiers, Unicode categories, alternation)
// are not yet supported.
//
// Supported features:
//   .        — matches any single character (except newline)
//   *        — zero or more of preceding (greedy)
//   +        — one or more of preceding (greedy)
//   ?        — zero or one of preceding (greedy)
//   ^        — start-of-string anchor
//   $        — end-of-string anchor
//   [abc]    — character class (literal chars)
//   [a-z]    — character range inside class
//   [^abc]   — negated character class
//   \d \w \s — digit, word, whitespace shorthands
//   \D \W \S — negated shorthands

fn is_metachar(c: Char) -> Bool {
  c == '.' || c == '*' || c == '+' || c == '?' || c == '^' || c == '$' || c == '[' || c == ']' || c == '\\' || c == '(' || c == ')' || c == '|' || c == '{' || c == '}'
}

fn is_digit_char(c: Char) -> Bool {
  c >= '0' && c <= '9'
}

fn is_word_char(c: Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_'
}

fn is_space_char(c: Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

fn class_end(pattern: Str, start: Int) -> Int {
  var pos = start + 1;
  while pos < pattern.len() {
    let pc = pattern.char_at(pos).unwrap();
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

fn class_matches(start: Int, pattern: Str, ch: Char) -> Bool {
  var negated = false;
  var pos = start + 1;
  if pos < pattern.len() && pattern.char_at(pos).unwrap() == '^' {
    negated = true;
    pos = pos + 1;
  };
  var matched = false;
  while pos < pattern.len() {
    let pc = pattern.char_at(pos).unwrap();
    if pc == ']' {
      break;
    };
    if pos + 2 < pattern.len() && pattern.char_at(pos + 1).unwrap() == '-' && pattern.char_at(pos + 2).unwrap() != ']' {
      let range_start = pc;
      let range_end = pattern.char_at(pos + 2).unwrap();
      if ch >= range_start && ch <= range_end {
        matched = true;
      };
      pos = pos + 3;
    } elif pc == '\\' && pos + 1 < pattern.len() {
      let esc = pattern.char_at(pos + 1).unwrap();
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

fn element_matches(pattern: Str, p_pos: Int, text: Str, t_pos: Int) -> Bool {
  if t_pos >= text.len() {
    return false;
  };
  let pc = pattern.char_at(p_pos).unwrap();
  let tc = text.char_at(t_pos).unwrap();
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
    let esc = pattern.char_at(p_pos + 1).unwrap();
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

fn match_here(pattern: Str, text: Str, p_pos: Int, t_pos: Int) -> Option[Int] {
  let p_len = pattern.len();
  if p_pos >= p_len {
    return Some(t_pos);
  };
  let pc = pattern.char_at(p_pos).unwrap();
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
    let qc = pattern.char_at(elem_end_raw).unwrap();
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

fn find_first_match(pattern: Str, text: Str) -> Option[Match] {
  let t_len = text.len();
  if pattern.len() > 0 && pattern.char_at(0).unwrap() == '^' {
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

pub fn Regex.new(pattern: Str) -> Result<Regex, Str> {
  if !is_valid_regex(pattern) {
    return Err("invalid regex pattern");
  };
  Ok(Regex{ pattern: pattern; compiled: 0; })
}

pub fn Regex.is_match(self, text: Str) -> Bool {
  find_first_match(self.pattern, text).is_some
}

pub fn Regex.find(self, text: Str) -> Option[Match]
  ensures: result.is_some => result.value.start >= 0 && result.value.end >= result.value.start
{
  find_first_match(self.pattern, text)
}

pub fn Regex.find_all(self, text: Str) -> Vec[Match] {
  var matches = Vec[Match].new();
  let pat = self.pattern;
  let t_len = text.len();
  if pat.len() == 0 {
    var pos: Int = 0;
    while pos <= t_len {
      matches.push(Match{ start: pos; end: pos; text: ""; });
      pos = pos + 1;
    };
    return matches;
  };
  let anchored = pat.char_at(0).unwrap() == '^';
  var pos: Int = 0;
  while pos <= t_len {
    let result = match_here(pat, text, if anchored { 1 } else { 0 }, pos);
    match result {
      Some(end) => {
        let matched = string.str_slice(text, pos, end);
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

pub fn Regex.captures(self, text: Str) -> Option<Captures> {
  let m = find_first_match(self.pattern, text);
  match m {
    Some(match_obj) => {
      var groups = Vec[Option[Match]].new();
      groups.push(Some(match_obj));
      Some(Captures{ groups: groups; })
    };
    None => None;
  }
}

pub fn Regex.replace(self, text: Str, replacement: Str) -> Str {
  let m = find_first_match(self.pattern, text);
  match m {
    Some(match_obj) => {
      let before = string.str_slice(text, 0, match_obj.start);
      let after = string.str_slice(text, match_obj.end, text.len());
      string.str_concat(string.str_concat(before, replacement), after)
    };
    None => text;
  }
}

pub fn Regex.replace_all(self, text: Str, replacement: Str) -> Str {
  let matches = find_all(self.pattern, text);
  if matches.len() == 0 {
    return text;
  };
  var result = "";
  var pos: Int = 0;
  var i: Int = 0;
  while i < matches.len() {
    result = string.str_concat(result, string.str_slice(text, pos, matches[i].start));
    result = string.str_concat(result, replacement);
    pos = matches[i].end;
    i = i + 1;
  };
  string.str_concat(result, string.str_slice(text, pos, text.len()))
}

pub fn Regex.split(self, text: Str) -> Vec[Str] {
  var result = Vec[Str].new();
  let pat = self.pattern;
  let t_len = text.len();
  if pat.len() == 0 {
    var pos: Int = 0;
    while pos < t_len {
      result.push(string.str_slice(text, pos, pos + 1));
      pos = pos + 1;
    };
    return result;
  };
  var seg_start: Int = 0;
  var pos: Int = 0;
  while pos <= t_len {
    let match_result = match_here(pat, text, 0, pos);
    match match_result {
      Some(end) => {
        result.push(string.str_slice(text, seg_start, pos));
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
  result.push(string.str_slice(text, seg_start, t_len));
  result
}

pub fn Regex.match_count(self, text: Str) -> Int {
  find_all(self.pattern, text).len()
}

pub fn Captures.get(self, index: Int) -> Option[Match] {
  if index < 0 || index >= self.groups.len() {
    return None;
  };
  self.groups[index]
}

pub fn Captures.get_named(self, name: Str) -> Option[Match] {
  None
}

pub fn Captures.len(self) -> Int {
  self.groups.len()
}

pub fn regex_escape(pattern: Str) -> Str {
  var result = "";
  var i: Int = 0;
  let p_len = pattern.len();
  while i < p_len {
    let c = pattern.char_at(i).unwrap();
    if is_metachar(c) {
      result = string.str_concat(result, "\\");
      result = string.str_concat(result, string.str_slice(pattern, i, i + 1));
    } else {
      result = string.str_concat(result, string.str_slice(pattern, i, i + 1));
    };
    i = i + 1;
  };
  result
}

pub fn is_valid_regex(pattern: Str) -> Bool {
  var i: Int = 0;
  var bracket_depth: Int = 0;
  let p_len = pattern.len();
  while i < p_len {
    let c = pattern.char_at(i).unwrap();
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
