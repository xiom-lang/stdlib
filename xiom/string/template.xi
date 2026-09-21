// XIOM - String: Template
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.template

// Depends on: xiom.string

// ============================================================================
// Named-placeholder string templates. Placeholders look like {{name}} and are
// substituted from a map of values. Compilation separates the source text from
// its placeholder list so one template can be rendered repeatedly without a
// re-parse. Pure, zero dependencies.
// ============================================================================

use xiom.string;

/// Compiled template: the original template text and the distinct named
/// placeholders it contains, in first-seen order. Constructed only by
/// `template_compile`.
pub type Template = {
  source: Str;
  placeholders: Vec[Str];
}

/// String map used by the render entry points: `keys` and `values` are
/// parallel vectors of equal length. `map_new` / `map_insert` build maps.
pub type Map = {
  keys: Vec[Str];
  values: Vec[Str];
}

/// Create an empty string map.
/// Params: none.
/// Returns: an empty Map.
/// Complexity: O(1).
pub fn map_new() -> Map {
  Map{ keys: Vec[Str].new(); values: Vec[Str].new(); }
}

/// Insert or replace `key` with `value` in `m`.
/// Params: m the map to mutate; key, value the pair to store.
/// Returns: nothing.
/// Complexity: O(|m|).
pub fn map_insert(m: &mut Map, key: Str, value: Str) {
  var i: Int = 0;
  while i < m.keys.len() {
    let k = m.keys[i];
    if k == key {
      m.values[i] = value;
      return;
    };
    i = i + 1;
  };
  m.keys.push(key);
  m.values.push(value);
}

// Masked byte at `pos` (BUG 22 #10: `as Int` sign-extends UInt8).
// Complexity: O(1).
fn _byte(s: Str, i: Int) -> Int {
  let v = string.byte_at(s, i) as Int;
  v & 0xFF
}

// Strict scan of `tpl`: collects the distinct placeholder names (when
// `collect` is true) and returns the total placeholder count. A backslash
// escapes the next character; a lone brace or an unclosed/empty/braced
// placeholder name yields Err.
// Complexity: O(|tpl|).
fn _scan_placeholders(tpl: Str, collect: Bool, names: &mut Vec[Str]) -> Result[Int, Str] {
  let len = string.str_len(tpl);
  var i: Int = 0;
  var count: Int = 0;
  while i < len {
    let c = _byte(tpl, i);
    if c == 92 {
      if i + 1 < len {
        i = i + 2;
      } else {
        i = i + 1;
      };
    } elif c == 123 && i + 1 < len && _byte(tpl, i + 1) == 123 {
      var j = i + 2;
      var bad = false;
      while j < len && _byte(tpl, j) != 125 {
        let cb = _byte(tpl, j);
        if cb == 123 {
          bad = true;
        };
        j = j + 1;
      };
      if bad {
        return Err("template: '{{' inside placeholder name");
      };
      if j >= len {
        return Err("template: unclosed '{{' placeholder");
      };
      if j + 1 >= len || _byte(tpl, j + 1) != 125 {
        return Err("template: expected '}}'");
      };
      let name = string.str_slice(tpl, i + 2, j);
      if string.str_len(name) == 0 {
        return Err("template: empty placeholder name");
      };
      count = count + 1;
      if collect {
        var present = false;
        var k: Int = 0;
        while k < names.len() {
          let nk = names[k];
          if nk == name {
            present = true;
          };
          k = k + 1;
        };
        if !present {
          names.push(name);
        };
      };
      i = j + 2;
    } elif c == 123 || c == 125 {
      return Err("template: unbalanced brace");
    } else {
      i = i + 1;
    };
  };
  Ok(count)
}

// Tolerant scan: counts well-formed {{name}} placeholders (and collects their
// distinct names), skipping backslash escapes, lone braces and malformed
// sequences without erroring. Used by the inspection entry points.
// Complexity: O(|tpl|).
fn _scan_tolerant(tpl: Str, names: &mut Vec[Str]) -> Int {
  let len = string.str_len(tpl);
  var i: Int = 0;
  var count: Int = 0;
  while i < len {
    let c = _byte(tpl, i);
    if c == 92 {
      if i + 1 < len {
        i = i + 2;
      } else {
        i = i + 1;
      };
    } elif c == 123 && i + 1 < len && _byte(tpl, i + 1) == 123 {
      var j = i + 2;
      while j < len && _byte(tpl, j) != 125 {
        j = j + 1;
      };
      if j < len && j + 1 < len && _byte(tpl, j + 1) == 125 && j > i + 2 {
        let name = string.str_slice(tpl, i + 2, j);
        var present = false;
        var k: Int = 0;
        while k < names.len() {
          let nk = names[k];
          if nk == name {
            present = true;
          };
          k = k + 1;
        };
        if !present {
          names.push(name);
        };
        count = count + 1;
        i = j + 2;
      } else {
        i = i + 1;
      };
    } else {
      i = i + 1;
    };
  };
  count
}

// Look up `name` in `values`. Returns the mapped value, or Ok(fallback) when
// missing (non-strict), or Err (strict).
// Complexity: O(|map|).
fn _lookup(values: &Map, name: Str, strict: Bool, fallback: Str) -> Result[Str, Str] {
  var i: Int = 0;
  while i < values.keys.len() {
    let k = values.keys[i];
    if k == name {
      let v = values.values[i];
      return Ok(v);
    };
    i = i + 1;
  };
  if strict {
    let msg = string.str_concat("template: missing value for '", string.str_concat(name, "'"));
    return Err(msg);
  };
  Ok(fallback)
}

// Render `tpl`, substituting {{name}} placeholders from `values`. A backslash
// escapes the following character literally; `\{` renders "{". When `strict`
// is set, a missing value is an Err; otherwise the missing value renders as
// `fallback`. Malformed placeholder syntax is always an Err.
// Complexity: O(|tpl| + |map lookups| * |map|).
fn _render(tpl: Str, values: &Map, strict: Bool, fallback: Str) -> Result[Str, Str] {
  var result = "";
  let len = string.str_len(tpl);
  var i: Int = 0;
  while i < len {
    let c = _byte(tpl, i);
    if c == 92 {
      if i + 1 < len {
        result = string.str_concat(result, string.str_slice(tpl, i + 1, i + 2));
        i = i + 2;
      } else {
        result = string.str_concat(result, string.str_slice(tpl, i, i + 1));
        i = i + 1;
      };
    } elif c == 123 && i + 1 < len && _byte(tpl, i + 1) == 123 {
      var j = i + 2;
      var bad = false;
      while j < len && _byte(tpl, j) != 125 {
        let cb = _byte(tpl, j);
        if cb == 123 {
          bad = true;
        };
        j = j + 1;
      };
      if bad {
        return Err("template: '{{' inside placeholder name");
      };
      if j >= len {
        return Err("template: unclosed '{{' placeholder");
      };
      if j + 1 >= len || _byte(tpl, j + 1) != 125 {
        return Err("template: expected '}}'");
      };
      let name = string.str_slice(tpl, i + 2, j);
      if string.str_len(name) == 0 {
        return Err("template: empty placeholder name");
      };
      let lr = _lookup(values, name, strict, fallback);
      match lr {
        Ok(v) => {
          result = string.str_concat(result, v);
        };
        Err(e) => {
          return Err(e);
        };
      };
      i = j + 2;
    } elif c == 123 || c == 125 {
      return Err("template: unbalanced brace");
    } else {
      result = string.str_concat(result, string.str_slice(tpl, i, i + 1));
      i = i + 1;
    };
  };
  Ok(result)
}

/// Parse `tpl` into a compiled Template, validating placeholder syntax. The
/// Template holds the source text and the distinct placeholder names.
/// Params: tpl the template text.
/// Returns: Ok with the compiled Template, Err on malformed placeholders.
/// Error case: unclosed placeholder, empty name, lone brace.
/// Complexity: O(|tpl|).
pub fn template_compile(tpl: Str) -> Result[Template, Str] {
  var names = Vec[Str].new();
  let r = _scan_placeholders(tpl, true, &names);
  match r {
    Err(e) => {
      return Err(e);
    };
    Ok(_) => {
      return Ok(Template{ source: tpl; placeholders: names; });
    };
  }
}

/// Render a compiled template using `values`. Placeholders missing from the
/// map render as the empty string.
/// Params: t the compiled template; values the value map.
/// Returns: Ok with the rendered string.
/// Error case: none (the template was already validated at compile time).
/// Complexity: O(|tpl| + |placeholders| * |map|).
pub fn template_render_compiled(t: &Template, values: &Map) -> Result[Str, Str] {
  let r = _render(t.source, values, false, "");
  r
}

/// Parse and render `tpl`, substituting placeholders from `values`.
/// Placeholders missing from the map render as the empty string.
/// Params: tpl the template text; values the value map.
/// Returns: Ok with the rendered string, Err on malformed placeholder syntax.
/// Error case: unclosed placeholder, empty name, lone brace.
/// Complexity: O(|tpl| + |placeholders| * |map|).
pub fn template_render(tpl: Str, values: &Map) -> Result[Str, Str] {
  let r = _render(tpl, values, false, "");
  r
}

/// Parse and render `tpl`, pairing `keys` with `values` positionally. A key
/// with no corresponding value renders as the empty string.
/// Params: tpl the template text; keys, values the parallel vectors.
/// Returns: Ok with the rendered string, Err on malformed placeholder syntax.
/// Error case: unclosed placeholder, empty name, lone brace.
/// Complexity: O(|tpl| + |placeholders| * |keys|).
pub fn template_render_map(tpl: Str, keys: &Vec[Str], values: &Vec[Str]) -> Result[Str, Str] {
  var m = Map{ keys: Vec[Str].new(); values: Vec[Str].new(); };
  var i: Int = 0;
  while i < keys.len() {
    let k = keys[i];
    var v = "";
    if i < values.len() {
      v = values[i];
    };
    m.keys.push(k);
    m.values.push(v);
    i = i + 1;
  };
  let r = _render(tpl, &m, false, "");
  r
}

/// Parse and render `tpl`, using `fallback` for placeholders missing from
/// `values`.
/// Params: tpl the template text; values the value map; fallback the value
///         used for missing placeholders.
/// Returns: Ok with the rendered string, Err on malformed placeholder syntax.
/// Error case: unclosed placeholder, empty name, lone brace.
/// Complexity: O(|tpl| + |placeholders| * |map|).
pub fn template_render_fallback(tpl: Str, values: &Map, fallback: Str) -> Result[Str, Str] {
  let r = _render(tpl, values, false, fallback);
  r
}

/// Parse and render `tpl`, returning Err when any placeholder is missing from
/// `values`.
/// Params: tpl the template text; values the value map.
/// Returns: Ok with the rendered string, Err on malformed syntax or a missing
///          value.
/// Error case: unclosed placeholder, empty name, lone brace, missing value.
/// Complexity: O(|tpl| + |placeholders| * |map|).
pub fn template_render_strict(tpl: Str, values: &Map) -> Result[Str, Str] {
  let r = _render(tpl, values, true, "");
  r
}

/// Escape literal text so "{{" and "}}" render verbatim: every backslash,
/// brace, or backslash-escaped sequence becomes a `\`-prefixed literal that
/// the renderer copies unchanged.
/// Params: s the literal text to escape.
/// Returns: the escaped text.
/// Error case: none.
/// Complexity: O(|s|).
pub fn template_escape(s: Str) -> Str {
  var result = "";
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let c = _byte(s, i);
    if c == 92 || c == 123 || c == 125 {
      result = string.str_concat(result, "\\");
      result = string.str_concat(result, string.str_slice(s, i, i + 1));
    } else {
      result = string.str_concat(result, string.str_slice(s, i, i + 1));
    };
    i = i + 1;
  };
  result
}

/// Reverse of `template_escape`: restores "{{" and "}}" from their escaped
/// forms. Only `\{`, `\}` and `\\` are unescaped; other backslash sequences
/// pass through unchanged.
/// Params: s the escaped text.
/// Returns: the restored text.
/// Error case: none.
/// Complexity: O(|s|).
pub fn template_unescape(s: Str) -> Str {
  var result = "";
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let c = _byte(s, i);
    if c == 92 && i + 1 < len {
      let n = _byte(s, i + 1);
      if n == 92 || n == 123 || n == 125 {
        result = string.str_concat(result, string.str_slice(s, i + 1, i + 2));
        i = i + 2;
      } else {
        result = string.str_concat(result, string.str_slice(s, i, i + 1));
        i = i + 1;
      };
    } else {
      result = string.str_concat(result, string.str_slice(s, i, i + 1));
      i = i + 1;
    };
  };
  result
}

/// Return true when `tpl` contains at least one well-formed "{{name}}"
/// placeholder (tolerant scan: malformed sequences do not count).
/// Params: tpl the template text.
/// Returns: true when a placeholder is present.
/// Complexity: O(|tpl|).
pub fn template_has_placeholders(tpl: Str) -> Bool {
  var names = Vec[Str].new();
  let n = _scan_tolerant(tpl, &names);
  n > 0
}

/// The distinct placeholder names in `tpl`, in first-seen order (tolerant
/// scan; malformed sequences are skipped).
/// Params: tpl the template text.
/// Returns: a Vec[Str] of distinct names.
/// Complexity: O(|tpl|).
pub fn template_placeholders(tpl: Str) -> Vec[Str] {
  var names = Vec[Str].new();
  let n = _scan_tolerant(tpl, &names);
  let _ = n;
  names
}

/// Total number of placeholder occurrences in `tpl` (tolerant scan).
/// Params: tpl the template text.
/// Returns: the placeholder count.
/// Complexity: O(|tpl|).
pub fn template_placeholder_count(tpl: Str) -> Int
  ensures: result >= 0
{
  var names = Vec[Str].new();
  let n = _scan_tolerant(tpl, &names);
  n
}

/// Validate `tpl`: checks for balanced, well-formed "{{name}}" placeholders.
/// Params: tpl the template text.
/// Returns: Ok(()) when valid, Err describing the first problem.
/// Error case: unclosed placeholder, empty name, lone brace, braces in a name.
/// Complexity: O(|tpl|).
pub fn template_validate(tpl: Str) -> Result[(), Str] {
  var names = Vec[Str].new();
  let r = _scan_placeholders(tpl, false, &names);
  match r {
    Err(e) => {
      return Err(e);
    };
    Ok(_) => {
      return Ok(());
    };
  }
}

