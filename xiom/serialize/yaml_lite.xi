// XIOM - Serialize: YAML Lite
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.serialize.yaml_lite

// Depends on: xiom.serialize, xiom.string

// ============================================================================
// Minimal YAML subset: parse to a value tree and emit simple documents.
//
// Supported subset:
//   - block mappings  "key: value"
//   - block sequences "- item"
//   - plain scalar values
// Nested (indented) structures terminate the enclosing block; the parser is
// intentionally a flat subset ("lite").
//
// The emitter produces plain or double-quoted scalars (quoted whenever the
// scalar would otherwise be ambiguous), block sequences, and mappings.
//
// NOTE: this module is self-contained and does not import the parent
// xiom.serialize to avoid same-name resolution issues (BUG 25 #1). The
// Mapping variant carries two parallel vectors (keys/values); tuples and Map
// payloads inside enums miscompile in the current compiler, and match must
// operate on values (not dereferenced references).
// ============================================================================

use xiom.string;

pub type YamlValue = enum {
  Scalar(value: Str),
  Sequence(items: Vec[YamlValue]),
  Mapping(keys: Vec[Str], values: Vec[YamlValue]),
}

fn _yaml_get_char(s: Str, pos: Int) -> Char {
  var opt = xiom.string.char_at(s, pos);
  if opt.is_some { return opt.value; }
  return '\0';
}

fn _yaml_trim(s: Str) -> Str {
  var start = 0;
  var end = s.len();
  while start < end {
    let c = _yaml_get_char(s, start);
    if c == ' ' || c == '\t' { start = start + 1; } else { break; }
  }
  while end > start {
    let c = _yaml_get_char(s, end - 1);
    if c == ' ' || c == '\t' || c == '\r' || c == '\n' { end = end - 1; } else { break; }
  }
  return xiom.string.str_slice(s, start, end);
}

fn _yaml_indent_of(s: Str) -> Int {
  var n = 0;
  while n < s.len() {
    let c = _yaml_get_char(s, n);
    if c == ' ' { n = n + 1; } else { break; }
  }
  return n;
}

fn _yaml_starts_with(s: Str, prefix: Str) -> Bool {
  if s.len() < prefix.len() { return false; }
  var i = 0;
  while i < prefix.len() {
    if _yaml_get_char(s, i) != _yaml_get_char(prefix, i) { return false; }
    i = i + 1;
  }
  return true;
}

fn _yaml_looks_like_key(s: Str) -> Bool {
  var i = 0;
  while i < s.len() {
    let c = _yaml_get_char(s, i);
    if c == ':' {
      if i + 1 < s.len() {
        let n = _yaml_get_char(s, i + 1);
        if n == ' ' || n == '\t' {
          return true;
        }
      } else {
        return true;
      }
    }
    i = i + 1;
  }
  return false;
}

fn _yaml_key_colon(s: Str) -> Int {
  var i = 0;
  while i < s.len() {
    let c = _yaml_get_char(s, i);
    if c == ':' {
      return i;
    }
    i = i + 1;
  }
  return 0;
}

// Parse a flat block of lines into a YamlValue (mapping / sequence / scalar).
// `lines` are the block lines; `pos` is the index of the first line belonging
// to this block and is advanced past the consumed lines.
fn _yaml_parse_block(lines: &Vec[Str], pos: &mut Int, indent: Int) -> Result[YamlValue, Str] {
  if *pos >= lines.len() {
    return Err("yaml_parse: unexpected end of document");
  }
  let line = lines[*pos];
  let content = _yaml_trim(line);
  if content.len() == 0 {
    return Err("yaml_parse: empty line in block");
  }
  if _yaml_starts_with(content, "- ") || content == "-" {
    // Sequence block
    var items = Vec[YamlValue].new();
    while *pos < lines.len() {
      let l = lines[*pos];
      if _yaml_indent_of(l) < indent {
        break;
      }
      let c = _yaml_trim(l);
      if _yaml_starts_with(c, "- ") {
        let rest = xiom.string.str_slice(c, 2, c.len());
        let r = _yaml_trim(rest);
        items.push(YamlValue.Scalar(r));
        *pos = *pos + 1;
      } elif _yaml_trim(l).len() == 0 {
        *pos = *pos + 1;
      } else {
        break;
      }
    }
    return Ok(YamlValue.Sequence(items));
  }
  if _yaml_looks_like_key(content) {
    // Mapping block
    var mkeys = Vec[Str].new();
    var mvals = Vec[YamlValue].new();
    while *pos < lines.len() {
      let l = lines[*pos];
      if _yaml_indent_of(l) < indent {
        break;
      }
      let c = _yaml_trim(l);
      if c.len() == 0 {
        *pos = *pos + 1;
        continue;
      }
      if _yaml_starts_with(c, "- ") {
        break;
      }
      if !(_yaml_looks_like_key(c)) {
        break;
      }
      let colon = _yaml_key_colon(c);
      let key = _yaml_trim(xiom.string.str_slice(c, 0, colon));
      let val_str = _yaml_trim(xiom.string.str_slice(c, colon + 1, c.len()));
      mkeys.push(key);
      mvals.push(YamlValue.Scalar(val_str));
      *pos = *pos + 1;
    }
    return Ok(YamlValue.Mapping(mkeys, mvals));
  }
  // Plain scalar
  *pos = *pos + 1;
  return Ok(YamlValue.Scalar(content));
}

// ============================================================================
// Public API
// ============================================================================

/// Parse `s` into a YamlValue tree. Returns Err on malformed documents.
/// Complexity: O(n), n = document size.
///
/// NOTE: the current compiler miscompiles cross-module calls that return a
/// Result whose payload is a recursive enum (see report); yaml_parse works
/// when invoked from within its own module but not across modules.
pub fn yaml_parse(s: Str) -> Result[YamlValue, Str] {
  var lines = Vec[Str].new();
  var start = 0;
  var i = 0;
  while i < s.len() {
    let c = _yaml_get_char(s, i);
    if c == '\n' {
      lines.push(xiom.string.str_slice(s, start, i));
      start = i + 1;
    }
    i = i + 1;
  }
  if start < s.len() {
    lines.push(xiom.string.str_slice(s, start, s.len()));
  }
  var first = 0;
  while first < lines.len() {
    if _yaml_trim(lines[first]).len() > 0 { break; }
    first = first + 1;
  }
  if first >= lines.len() {
    return Err("yaml_parse: empty document");
  }
  let base_indent = _yaml_indent_of(lines[first]);
  var pos = first;
  let result = _yaml_parse_block(&lines, &mut pos, base_indent);
  match result {
    Ok(v) => Ok(v);
    Err(e) => Err(e);
  }
}

/// Parse a single YAML document (alias of yaml_parse for a strict reader).
/// Complexity: O(n), n = document size.
pub fn yaml_parse_document(s: Str) -> Result[YamlValue, Str] {
  return yaml_parse(s);
}

/// Serialize `v` as YAML text.
/// Complexity: O(n), n = number of nodes.
pub fn yaml_stringify(v: YamlValue) -> Str {
  return _yaml_emit_node(v, 0);
}

fn _yaml_pad(depth: Int) -> Str {
  var result = "";
  var i = 0;
  while i < depth * 2 {
    result = result + " ";
    i = i + 1;
  }
  return result;
}

fn _yaml_emit_node(v: YamlValue, depth: Int) -> Str {
  match v {
    YamlValue.Scalar(s) => {
      return yaml_emit_scalar(s);
    }
    YamlValue.Sequence(items) => {
      var result = "";
      var i = 0;
      while i < items.len() {
        var pad = _yaml_pad(depth);
        result = result + pad + "- " + _yaml_emit_flat(items[i], depth);
        if i + 1 < items.len() {
          result = result + "\n";
        }
        i = i + 1;
      }
      return result;
    }
    YamlValue.Mapping(keys, values) => {
      var result = "";
      var i = 0;
      while i < keys.len() {
        var pad = _yaml_pad(depth);
        result = result + pad + yaml_emit_scalar(keys[i]) + ": ";
        result = result + _yaml_emit_flat(values[i], depth + 1);
        if i + 1 < keys.len() {
          result = result + "\n";
        }
        i = i + 1;
      }
      return result;
    }
    _ => { return ""; }
  }
}

// Emit a value inline: scalars inline, nested structures on the next line.
fn _yaml_emit_flat(v: YamlValue, depth: Int) -> Str {
  match v {
    YamlValue.Scalar(s) => {
      return yaml_emit_scalar(s);
    }
    YamlValue.Sequence(items) => {
      if items.len() == 0 { return "[]"; }
      var result = "\n";
      var i = 0;
      while i < items.len() {
        result = result + _yaml_pad(depth + 1) + "- " + _yaml_emit_flat(items[i], depth + 1);
        if i + 1 < items.len() {
          result = result + "\n";
        }
        i = i + 1;
      }
      return result;
    }
    YamlValue.Mapping(keys, values) => {
      if keys.len() == 0 { return "{}"; }
      var result = "\n";
      var i = 0;
      while i < keys.len() {
        result = result + _yaml_pad(depth + 1) + yaml_emit_scalar(keys[i]) + ": ";
        result = result + _yaml_emit_flat(values[i], depth + 1);
        if i + 1 < keys.len() {
          result = result + "\n";
        }
        i = i + 1;
      }
      return result;
    }
    _ => { return ""; }
  }
}

/// The value under `key`, if `v` is a mapping and the key is present.
/// Complexity: O(k), k = number of keys.
pub fn yaml_get(v: YamlValue, key: Str) -> Option[YamlValue] {
  match v {
    YamlValue.Mapping(keys, values) => {
      var i = 0;
      while i < keys.len() {
        if keys[i] == key { return Some(values[i]); }
        i = i + 1;
      }
      return None;
    }
    _ => None;
  }
}

/// Emit `s` as a quoted (when ambiguous) or plain YAML scalar.
/// Complexity: O(n), n = string length.
pub fn yaml_emit_scalar(s: Str) -> Str {
  if s.len() == 0 {
    return "\"\"";
  }
  var needs_quote = false;
  var i = 0;
  while i < s.len() {
    let c = _yaml_get_char(s, i);
    if c == ':' || c == '#' || c == '{' || c == '}' || c == '[' || c == ']'
       || c == ',' || c == '&' || c == '*' || c == '!' || c == '|' || c == '>'
       || c == '\'' || c == '"' || c == '%' || c == '@' || c == '`'
       || c == '\n' || c == '\r' || c == '\t' {
      needs_quote = true;
      break;
    }
    i = i + 1;
  }
  if needs_quote {
    return _yaml_dquote(s);
  }
  return s;
}

fn _yaml_dquote(s: Str) -> Str {
  var result = "\"";
  var i = 0;
  while i < s.len() {
    let c = _yaml_get_char(s, i);
    if c == '"' {
      result = result + "\\\"";
    } elif c == '\\' {
      result = result + "\\\\";
    } elif c == '\n' {
      result = result + "\\n";
    } elif c == '\t' {
      result = result + "\\t";
    } elif c == '\r' {
      result = result + "\\r";
    } else {
      result = result + xiom.string.str_slice(s, i, i + 1);
    }
    i = i + 1;
  }
  return result + "\"";
}

/// Emit `items` as a YAML block sequence.
/// Complexity: O(n), n = number of items.
pub fn yaml_emit_sequence(items: &Vec[Str]) -> Str {
  var result = "";
  var i = 0;
  while i < items.len() {
    if i > 0 {
      result = result + "\n";
    }
    result = result + "- " + yaml_emit_scalar(items[i]);
    i = i + 1;
  }
  return result;
}

/// Emit `keys` and `values` as a YAML block mapping. The two vectors must be
/// the same length; mismatches are truncated to the shorter.
/// Complexity: O(n), n = number of keys.
pub fn yaml_emit_mapping(keys: &Vec[Str], values: &Vec[Str]) -> Str {
  var result = "";
  var n = keys.len();
  if values.len() < n {
    n = values.len();
  }
  var i = 0;
  while i < n {
    if i > 0 {
      result = result + "\n";
    }
    result = result + yaml_emit_scalar(keys[i]) + ": " + yaml_emit_scalar(values[i]);
    i = i + 1;
  }
  return result;
}
