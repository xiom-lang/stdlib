// XIOM - Regex: Syntax
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.regex.syntax

// Depends on: xiom.string

use xiom.string;
use xiom.convert;
use xiom.regex.engine;

// ============================================================================
// Regex pattern syntax utilities: escape, parse, validate, build blocks.
// ============================================================================

/// A summary syntax tree for a validated pattern. `node_count` is the number
/// of pattern elements, `group_count` the number of `(...)` groups and
/// `class_count` the number of character classes. This engine supports no
/// groups, so `group_count` is always 0 for valid patterns.
pub type Ast = {
  pattern: Str;
  node_count: Int;
  group_count: Int;
  class_count: Int;
} derive[Clone]

/// True when `c` is a regex metacharacter.
fn is_metachar(c: Char) -> Bool {
  c == '.' || c == '*' || c == '+' || c == '?' || c == '^' || c == '$' || c == '[' || c == ']' || c == '\\' || c == '(' || c == ')' || c == '|' || c == '{' || c == '}'
}

/// The next byte at `pos` as an Int, or -1 past the end.
fn peek_byte(s: Str, pos: Int, len: Int) -> Int {
  if pos >= len {
    return -1;
  };
  string.byte_at(s, pos) as Int
}

/// Escape every metacharacter in `s` so the text matches literally.
/// Complexity: O(len(s)).
pub fn regex_escape(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  let p_len = s.len();
  while i < p_len {
    let c = s.char_at(i);
    if is_metachar(c) {
      result = string.str_concat(result, "\\");
    };
    result = string.str_concat(result, string.str_slice(s, i, i + 1));
    i = i + 1;
  };
  result
}

/// Decode escape sequences back to plain text. Handles escaped metacharacters
/// (`\*`, `\\`, `\[`, ...) and the standard control escapes `\n`, `\t`, `\r`.
/// Any other `\x` sequence decodes to the literal character `x`. A trailing
/// backslash is an error.
/// Complexity: O(len(s)).
pub fn regex_unescape(s: Str) -> Result[Str, Str] {
  var result = "";
  var i: Int = 0;
  let p_len = s.len();
  while i < p_len {
    let c = string.byte_at(s, i);
    if c == 92 {
      if i + 1 >= p_len {
        return Err("trailing backslash");
      };
      let n = string.byte_at(s, i + 1);
      if n == 110 {
        result = string.str_concat(result, "\n");
      } elif n == 116 {
        result = string.str_concat(result, "\t");
      } elif n == 114 {
        result = string.str_concat(result, "\r");
      } else {
        result = string.str_concat(result, string.str_slice(s, i + 1, i + 2));
      };
      i = i + 2;
    } else {
      result = string.str_concat(result, string.str_slice(s, i, i + 1));
      i = i + 1;
    };
  };
  Ok(result)
}

/// Parse `pattern` into a summary `Ast`, or `Err` when the syntax is invalid.
/// The AST counts pattern elements, groups and character classes.
/// Complexity: O(len(pattern)).
pub fn regex_parse(pattern: Str) -> Result[Ast, Str] {
  let compiled = engine.regex_compile(pattern);
  match compiled {
    Ok(_) => {};
    Err(e) => {
      return Err(e);
    };
  };
  var nodes: Int = 0;
  var groups: Int = 0;
  var classes: Int = 0;
  var i: Int = 0;
  let p_len = pattern.len();
  while i < p_len {
    let c = pattern.char_at(i);
    if c == '[' {
      classes = classes + 1;
      let end = class_end_index(pattern, i);
      nodes = nodes + 1;
      i = end;
    } elif c == '\\' {
      if i + 1 < p_len {
        nodes = nodes + 1;
        i = i + 1;
      };
    } elif c == '(' {
      groups = groups + 1;
      nodes = nodes + 1;
    } elif c == '*' || c == '+' || c == '?' {
      // quantifiers attach to the previous element; count only elements
    } else {
      nodes = nodes + 1;
    };
    i = i + 1;
  };
  Ok(Ast{ pattern: pattern; node_count: nodes; group_count: groups; class_count: classes; })
}

/// Index just past the closing ']' of the class starting at `start`.
fn class_end_index(pattern: Str, start: Int) -> Int {
  var pos = start + 1;
  while pos < pattern.len() {
    let pc = pattern.char_at(pos);
    if pc == ']' {
      return pos + 1;
    };
    if pc == '\\' && pos + 1 < pattern.len() {
      pos = pos + 1;
    };
    pos = pos + 1;
  };
  pattern.len()
}

/// True when `pattern` is syntactically valid (balanced classes, no dangling
/// escape or leading quantifier).
/// Complexity: O(len(pattern)).
pub fn regex_validate(pattern: Str) -> Bool {
  let compiled = engine.regex_compile(pattern);
  compiled.is_ok
}

/// The first syntax error message for `pattern`, or None when it is valid.
/// Complexity: O(len(pattern)).
pub fn regex_syntax_error(pattern: Str) -> Option[Str] {
  let compiled = engine.regex_compile(pattern);
  match compiled {
    Ok(_) => None;
    Err(e) => Some(e);
  }
}

/// Pattern text for a named character class. Supported names:
/// `alpha`, `digit`, `space`, `alnum`, `upper`, `lower`, `word`, `xdigit`,
/// `punct`, `graph`, `print`, `any`. Unknown names return the empty string.
/// Complexity: O(1).
pub fn regex_character_class(name: Str) -> Str {
  if name.len() == 0 {
    return "";
  };
  let upper = string.str_upper(name);
  if upper == "ALPHA" || upper == "LETTER" {
    return "[a-zA-Z]";
  };
  if upper == "DIGIT" {
    return "[0-9]";
  };
  if upper == "SPACE" || upper == "WHITESPACE" {
    return "[ \t\n\r]";
  };
  if upper == "ALNUM" {
    return "[a-zA-Z0-9]";
  };
  if upper == "UPPER" {
    return "[A-Z]";
  };
  if upper == "LOWER" {
    return "[a-z]";
  };
  if upper == "WORD" {
    return "[a-zA-Z0-9_]";
  };
  if upper == "XDIGIT" || upper == "HEX" || upper == "HEXDIGIT" {
    return "[0-9a-fA-F]";
  };
  if upper == "PUNCT" || upper == "PUNCTUATION" {
    return "[!-/:-@[-`{-~]";
  };
  if upper == "GRAPH" || upper == "PRINT" {
    return "[ -~]";
  };
  if upper == "ANY" || upper == "ANYCHAR" {
    return ".";
  };
  ""
}

/// Build the pattern text for a `{min,max}` quantifier. When `max == min` the
/// shorthand `{min}` is emitted, when `max < 0` the open form `{min,}` is
/// emitted. Invalid ranges (max >= 0 and max < min, or min < 0) return "".
/// Complexity: O(1).
pub fn regex_quantifier(min: Int, max: Int) -> Str {
  if min < 0 {
    return "";
  };
  if max >= 0 && max < min {
    return "";
  };
  if max == min {
    return "{" + convert.int_to_string(min) + "}";
  };
  if max < 0 {
    return "{" + convert.int_to_string(min) + ",}";
  };
  "{" + convert.int_to_string(min) + "," + convert.int_to_string(max) + "}"
}
