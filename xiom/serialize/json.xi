// XIOM - Serialize: JSON
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.serialize.json

// Depends on: xiom.serialize, xiom.string, xiom.convert

// ============================================================================
// JSON parsing, stringification, and tree navigation.
//
// This module is a standalone JSON engine. It intentionally does NOT import
// the parent module xiom.serialize, which defines same-named helpers
// (json_parse, json_escape, ...) that collide with the frozen API here and
// misresolve under the current compiler (BUG 25 #1). Object payloads use the
// same Map[Str, JsonValue] shape as the parent's JsonValue so the enum layout
// stays identical (diverging layouts break LLVM lowering).
//
// Security notes:
//   - json_parse rejects trailing characters, malformed tokens, unterminated
//     strings/escapes, and out-of-range escapes with a descriptive Err.
//   - json_escape handles the standard control escapes; the backslash, quote,
//     and control characters are always escaped so output is embeddable.
//   - Number parsing accepts the JSON grammar subset (no NaN/Infinity).
// ============================================================================

use xiom.string;
use xiom.convert;
use xiom.encoding;
use xiom.collections;

// NOTE: The parent module xiom.serialize is always present in the compile
// unit when any xiom.serialize.* submodule is used, and it defines its own
// `JsonValue` type (Object: Map[Str, JsonValue]). The compiler unifies the
// two same-named types, so this module MUST use the identical enum shape
// (Map-backed objects) or LLVM lowering fails.
pub type JsonValue = enum {
  Null,
  Bool(value: Bool),
  Number(value: Float64),
  String(value: Str),
  Array(items: Vec[JsonValue]),
  Object(entries: Map[Str, JsonValue]),
}

// ============================================================================
// Character + whitespace helpers
// ============================================================================

fn _json_get_char(s: Str, pos: Int) -> Char {
  var opt = xiom.string.char_at(s, pos);
  if opt.is_some { return opt.value; }
  return '\0';
}

fn _json_skip_ws(s: Str, pos: &mut Int) {
  while *pos < s.len() {
    let c = _json_get_char(s, *pos);
    if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
      *pos = *pos + 1;
    } else {
      return;
    }
  }
}

// ============================================================================
// Parser (recursive descent)
// ============================================================================

fn _json_parse_value(s: Str, pos: &mut Int) -> Result[JsonValue, Str] {
  _json_skip_ws(s, pos);
  if *pos >= s.len() {
    return Err("json_parse: unexpected end of input");
  }
  let c = _json_get_char(s, *pos);
  if c == '{' { return _json_parse_object(s, pos); }
  if c == '[' { return _json_parse_array(s, pos); }
  if c == '"' { return _json_parse_string_val(s, pos); }
  if c == 't' { return _json_parse_literal(s, pos, "true", JsonValue.Bool(true)); }
  if c == 'f' { return _json_parse_literal(s, pos, "false", JsonValue.Bool(false)); }
  if c == 'n' { return _json_parse_literal(s, pos, "null", JsonValue.Null); }
  if c == '-' || _json_is_digit(c) { return _json_parse_number(s, pos); }
  return Err("json_parse: unexpected character");
}

fn _json_is_digit(c: Char) -> Bool {
  return c >= '0' && c <= '9';
}

fn _json_parse_literal(s: Str, pos: &mut Int, word: Str, val: JsonValue) -> Result[JsonValue, Str] {
  var i = 0;
  while i < word.len() {
    if *pos + i >= s.len() {
      return Err("json_parse: unterminated literal");
    }
    let c = _json_get_char(s, *pos + i);
    let wc = _json_get_char(word, i);
    if c != wc {
      return Err("json_parse: invalid literal");
    }
    i = i + 1;
  }
  *pos = *pos + word.len();
  return Ok(val);
}

fn _json_parse_object(s: Str, pos: &mut Int) -> Result[JsonValue, Str] {
  *pos = *pos + 1;
  var entries = Map[Str, JsonValue].new();
  _json_skip_ws(s, pos);
  if *pos < s.len() {
    let c = _json_get_char(s, *pos);
    if c == '}' {
      *pos = *pos + 1;
      return Ok(JsonValue.Object(entries));
    }
  }
  loop {
    _json_skip_ws(s, pos);
    if *pos >= s.len() {
      return Err("json_parse: expected object key");
    }
    let key_result = _json_parse_string_val(s, pos);
    var key = "";
    match key_result {
      Ok(kv) => {
        match kv {
          JsonValue.String(k) => key = k;
          _ => { return Err("json_parse: object key is not a string"); }
        }
      }
      Err(e) => { return Err(e); }
    }
    _json_skip_ws(s, pos);
    if *pos >= s.len() {
      return Err("json_parse: expected ':'");
    }
    let colon = _json_get_char(s, *pos);
    if colon != ':' {
      return Err("json_parse: expected ':'");
    }
    *pos = *pos + 1;
    let value_result = _json_parse_value(s, pos);
    match value_result {
      Ok(v) => entries.insert(key, v);
      Err(e) => { return Err(e); }
    }
    _json_skip_ws(s, pos);
    if *pos >= s.len() {
      return Err("json_parse: expected '}' or ','");
    }
    let next = _json_get_char(s, *pos);
    if next == '}' {
      *pos = *pos + 1;
      return Ok(JsonValue.Object(entries));
    }
    if next == ',' {
      *pos = *pos + 1;
    } else {
      return Err("json_parse: expected '}' or ','");
    }
  }
  return Err("json_parse: unexpected end of object");
}

fn _json_parse_array(s: Str, pos: &mut Int) -> Result[JsonValue, Str] {
  *pos = *pos + 1;
  var items = Vec[JsonValue].new();
  _json_skip_ws(s, pos);
  if *pos < s.len() {
    let c = _json_get_char(s, *pos);
    if c == ']' {
      *pos = *pos + 1;
      return Ok(JsonValue.Array(items));
    }
  }
  loop {
    let value_result = _json_parse_value(s, pos);
    match value_result {
      Ok(v) => items.push(v);
      Err(e) => { return Err(e); }
    }
    _json_skip_ws(s, pos);
    if *pos >= s.len() {
      return Err("json_parse: expected ']' or ','");
    }
    let next = _json_get_char(s, *pos);
    if next == ']' {
      *pos = *pos + 1;
      return Ok(JsonValue.Array(items));
    }
    if next == ',' {
      *pos = *pos + 1;
    } else {
      return Err("json_parse: expected ']' or ','");
    }
  }
  return Err("json_parse: unexpected end of array");
}

fn _json_parse_string_val(s: Str, pos: &mut Int) -> Result[JsonValue, Str] {
  if *pos >= s.len() {
    return Err("json_parse: unterminated string");
  }
  *pos = *pos + 1;
  var result = "";
  var start = *pos;
  loop {
    if *pos >= s.len() {
      return Err("json_parse: unterminated string");
    }
    let c = _json_get_char(s, *pos);
    if c == '"' {
      if start < *pos {
        result = result + xiom.string.str_slice(s, start, *pos);
      }
      *pos = *pos + 1;
      return Ok(JsonValue.String(result));
    }
    if c == '\\' {
      if start < *pos {
        result = result + xiom.string.str_slice(s, start, *pos);
      }
      *pos = *pos + 1;
      if *pos >= s.len() {
        return Err("json_parse: unterminated escape");
      }
      let esc = _json_get_char(s, *pos);
      if esc == '"' {
        result = result + "\"";
      } elif esc == '\\' {
        result = result + "\\";
      } elif esc == '/' {
        result = result + "/";
      } elif esc == 'b' {
        result = result + "\b";
      } elif esc == 'f' {
        result = result + "\f";
      } elif esc == 'n' {
        result = result + "\n";
      } elif esc == 'r' {
        result = result + "\r";
      } elif esc == 't' {
        result = result + "\t";
      } elif esc == 'u' {
        *pos = *pos + 1;
        var code: Int = 0;
        var j = 0;
        while j < 4 {
          if *pos >= s.len() {
            return Err("json_parse: unterminated unicode escape");
          }
          let hc = _json_get_char(s, *pos);
          var hv = _json_hex_value(hc);
          if hv < 0 {
            return Err("json_parse: invalid unicode escape");
          }
          code = code * 16 + hv;
          *pos = *pos + 1;
          j = j + 1;
        }
        var cp = code as UInt32;
        var utf = Vec[UInt8].new();
        if cp < 0x80 {
          utf.push(cp as UInt8);
        } elif cp < 0x800 {
          utf.push((0xC0 | (cp >> 6)) as UInt8);
          utf.push((0x80 | (cp & 0x3F)) as UInt8);
        } elif cp < 0x10000 {
          utf.push((0xE0 | (cp >> 12)) as UInt8);
          utf.push((0x80 | ((cp >> 6) & 0x3F)) as UInt8);
          utf.push((0x80 | (cp & 0x3F)) as UInt8);
        } else {
          utf.push((0xF0 | (cp >> 18)) as UInt8);
          utf.push((0x80 | ((cp >> 12) & 0x3F)) as UInt8);
          utf.push((0x80 | ((cp >> 6) & 0x3F)) as UInt8);
          utf.push((0x80 | (cp & 0x3F)) as UInt8);
        }
        var dec = xiom.encoding.utf8_decode(&utf);
        match dec {
          Ok(strv) => result = result + strv;
          Err(_) => result = result + "?";
        }
        start = *pos;
      } else {
        return Err("json_parse: invalid escape character");
      }
      *pos = *pos + 1;
      start = *pos;
    } else {
      *pos = *pos + 1;
    }
  }
}

fn _json_hex_value(c: Char) -> Int {
  if c >= '0' && c <= '9' { return (c as Int) - 48; }
  if c >= 'a' && c <= 'f' { return (c as Int) - 87; }
  if c >= 'A' && c <= 'F' { return (c as Int) - 55; }
  return -1;
}

fn _json_parse_number(s: Str, pos: &mut Int) -> Result[JsonValue, Str] {
  var start = *pos;
  if *pos < s.len() {
    let c = _json_get_char(s, *pos);
    if c == '-' {
      *pos = *pos + 1;
    }
  }
  if *pos >= s.len() {
    return Err("json_parse: expected number");
  }
  while *pos < s.len() {
    let c = _json_get_char(s, *pos);
    if !(_json_is_digit(c)) { break; }
    *pos = *pos + 1;
  }
  if *pos < s.len() {
    let c = _json_get_char(s, *pos);
    if c == '.' {
      *pos = *pos + 1;
      while *pos < s.len() {
        let d = _json_get_char(s, *pos);
        if !(_json_is_digit(d)) { break; }
        *pos = *pos + 1;
      }
    }
  }
  if *pos < s.len() {
    let c = _json_get_char(s, *pos);
    if c == 'e' || c == 'E' {
      *pos = *pos + 1;
      if *pos < s.len() {
        let d = _json_get_char(s, *pos);
        if d == '+' || d == '-' {
          *pos = *pos + 1;
        }
      }
      while *pos < s.len() {
        let d = _json_get_char(s, *pos);
        if !(_json_is_digit(d)) { break; }
        *pos = *pos + 1;
      }
    }
  }
  if *pos == start {
    return Err("json_parse: expected number");
  }
  let num_str = xiom.string.str_slice(s, start, *pos);
  let parsed = xiom.core.to_float_from_str(num_str);
  match parsed {
    Ok(n) => Ok(JsonValue.Number(n));
    Err(_) => Err("json_parse: invalid number format");
  }
}

// ============================================================================
// Public API
// ============================================================================

/// Parse `s` into a JsonValue tree. Returns Err with a descriptive message
/// on malformed input or trailing garbage.
/// Complexity: O(n), n = input length.
///
/// NOTE: the name `json_parse` collides with the parent module's own
/// json_parse and direct calls can misresolve under the current compiler
/// (BUG 25 #1). The parsing logic lives in the uniquely-named helpers above.
pub fn json_parse(s: Str) -> Result[JsonValue, Str] {
  var pos = 0;
  let result = _json_parse_value(s, &pos);
  match result {
    Ok(v) => {
      _json_skip_ws(s, &pos);
      if pos != s.len() {
        return Err("json_parse: trailing characters after value");
      }
      return Ok(v);
    }
    Err(e) => { return Err(e); }
  }
}

/// Serialize `v` as compact JSON (no insignificant whitespace).
/// Complexity: O(n), n = number of nodes.
pub fn json_stringify(v: JsonValue) -> Str {
  return _json_stringify_node(v, 0);
}

fn _json_stringify_node(v: JsonValue, depth: Int) -> Str {
  match v {
    JsonValue.Null => {
      return "null";
    }
    JsonValue.Bool(b) => {
      if b { return "true"; }
      return "false";
    }
    JsonValue.Number(f) => {
      return convert.float_to_string(f);
    }
    JsonValue.String(s) => {
      return "\"" + _json_escape_impl(s) + "\"";
    }
    JsonValue.Array(items) => {
      var result = "[";
      var i = 0;
      while i < items.len() {
        if i > 0 { result = result + ","; }
        result = result + _json_stringify_node(items[i], depth);
        i = i + 1;
      }
      return result + "]";
    }
    JsonValue.Object(entries) => {
      var result = "{";
      var i = 0;
      while i < entries.keys.len() {
        if i > 0 { result = result + ","; }
        result = result + "\"" + _json_escape_impl(entries.keys[i]) + "\":";
        result = result + _json_stringify_node(entries.values[i], depth);
        i = i + 1;
      }
      return result + "}";
    }
  }
}

/// Serialize `v` as indented JSON (2 spaces per level).
/// Complexity: O(n), n = number of nodes.
pub fn json_pretty(v: JsonValue) -> Str {
  return _json_pretty_node(v, 0);
}

fn _json_indent(depth: Int) -> Str {
  var result = "";
  var i = 0;
  while i < depth {
    result = result + "  ";
    i = i + 1;
  }
  return result;
}

fn _json_pretty_node(v: JsonValue, depth: Int) -> Str {
  match v {
    JsonValue.Null => {
      return "null";
    }
    JsonValue.Bool(b) => {
      if b { return "true"; }
      return "false";
    }
    JsonValue.Number(f) => {
      return convert.float_to_string(f);
    }
    JsonValue.String(s) => {
      return "\"" + _json_escape_impl(s) + "\"";
    }
    JsonValue.Array(items) => {
      if items.len() == 0 { return "[]"; }
      var result = "[\n";
      var i = 0;
      while i < items.len() {
        result = result + _json_indent(depth + 1);
        result = result + _json_pretty_node(items[i], depth + 1);
        if i + 1 < items.len() { result = result + ","; }
        result = result + "\n";
        i = i + 1;
      }
      result = result + _json_indent(depth) + "]";
      return result;
    }
    JsonValue.Object(entries) => {
      if entries.keys.len() == 0 { return "{}"; }
      var result = "{\n";
      var i = 0;
      while i < entries.keys.len() {
        result = result + _json_indent(depth + 1);
        result = result + "\"" + _json_escape_impl(entries.keys[i]) + "\": ";
        result = result + _json_pretty_node(entries.values[i], depth + 1);
        if i + 1 < entries.keys.len() { result = result + ","; }
        result = result + "\n";
        i = i + 1;
      }
      result = result + _json_indent(depth) + "}";
      return result;
    }
  }
}

/// The value under `key`, if `v` is an object and the key is present.
/// Complexity: O(k), k = number of keys.
pub fn json_get(v: JsonValue, key: Str) -> Option[JsonValue] {
  match v {
    JsonValue.Object(entries) => {
      var i = 0;
      while i < entries.keys.len() {
        if entries.keys[i] == key { return Some(entries.values[i]); }
        i = i + 1;
      }
      return None;
    }
    _ => None;
  }
}

/// The value at a key path (e.g. ["user", "address", "city"]), navigating
/// objects by string key and arrays by numeric string index.
/// Complexity: O(d * k), d = path depth, k = keys per object.
pub fn json_get_path(v: JsonValue, path: &Vec[Str]) -> Option[JsonValue] {
  var node = v;
  var i = 0;
  while i < path.len() {
    var key = path[i];
    var is_index = false;
    var arr_idx: Int = 0;
    var di = 0;
    if key.len() > 0 {
      var first = _json_get_char(key, 0);
      if first >= '0' && first <= '9' {
        is_index = true;
        while di < key.len() {
          let dc = _json_get_char(key, di);
          if dc < '0' || dc > '9' { is_index = false; break; }
          arr_idx = arr_idx * 10 + ((dc as Int) - 48);
          di = di + 1;
        }
      }
    }
    if is_index {
      var found: Option[JsonValue];
      found = None;
      match node {
        JsonValue.Array(items) => {
          if arr_idx >= 0 && arr_idx < items.len() {
            found = Some(items[arr_idx]);
          }
        }
        _ => {}
      }
      match found {
        Some(n) => node = n;
        None => { return None; }
      }
    } else {
      var got = json_get(node, key);
      match got {
        Some(n) => node = n;
        None => { return None; }
      }
    }
    i = i + 1;
  }
  return Some(node);
}

/// A copy of `v` (an object) with `key` set to `value`. An existing key is
/// replaced; a missing key is appended.
/// Complexity: O(k), k = number of keys.
pub fn json_set(v: JsonValue, key: Str, value: JsonValue) -> JsonValue {
  var entries = Map[Str, JsonValue].new();
  var replaced = false;
  match v {
    JsonValue.Object(old) => {
      var i = 0;
      while i < old.keys.len() {
        if old.keys[i] == key {
          entries.insert(key, value);
          replaced = true;
        } else {
          entries.insert(old.keys[i], old.values[i]);
        }
        i = i + 1;
      }
    }
    _ => {}
  }
  if !replaced {
    entries.insert(key, value);
  }
  return JsonValue.Object(entries);
}

/// A copy of the array `v` with `item` appended. Non-array values produce an
/// array containing just `item`.
/// Complexity: O(k), k = number of items.
pub fn json_array_push(v: JsonValue, item: JsonValue) -> JsonValue {
  var items = Vec[JsonValue].new();
  match v {
    JsonValue.Array(old) => {
      var i = 0;
      while i < old.len() {
        items.push(old[i]);
        i = i + 1;
      }
    }
    _ => {}
  }
  items.push(item);
  return JsonValue.Array(items);
}

/// A new empty JSON object.
/// Complexity: O(1).
pub fn json_object_new() -> JsonValue {
  return JsonValue.Object(Map[Str, JsonValue].new());
}

/// A new empty JSON array.
/// Complexity: O(1).
pub fn json_array_new() -> JsonValue {
  return JsonValue.Array(Vec[JsonValue].new());
}

/// Wrap a float as a JSON number.
/// Complexity: O(1).
pub fn json_number(f: Float64) -> JsonValue {
  return JsonValue.Number(f);
}

/// Wrap a string as a JSON string.
/// Complexity: O(1).
pub fn json_string(s: Str) -> JsonValue {
  return JsonValue.String(s);
}

/// Wrap a bool as a JSON bool.
/// Complexity: O(1).
pub fn json_bool(b: Bool) -> JsonValue {
  return JsonValue.Bool(b);
}

/// The JSON null value.
/// Complexity: O(1).
pub fn json_null() -> JsonValue {
  return JsonValue.Null;
}

/// The type name of `v`: object, array, string, number, bool, or null.
/// Complexity: O(1).
pub fn json_type(v: JsonValue) -> Str {
  match v {
    JsonValue.Null => "null";
    JsonValue.Bool(_) => "bool";
    JsonValue.Number(_) => "number";
    JsonValue.String(_) => "string";
    JsonValue.Array(_) => "array";
    JsonValue.Object(_) => "object";
  }
}

/// Escape `s` for embedding inside a JSON string literal (without the
/// surrounding quotes). Handles \" \\ \/ \b \f \n \r \t and control chars.
/// Complexity: O(n), n = string length.
///
/// NOTE: the name `json_escape` collides with the parent module's own
/// json_escape; the logic lives in the uniquely-named _json_escape_impl.
pub fn json_escape(s: Str) -> Str {
  return _json_escape_impl(s);
}

fn _json_escape_impl(s: Str) -> Str {
  var result = "";
  var i = 0;
  while i < s.len() {
    let c = _json_get_char(s, i);
    if c == '"' {
      result = result + "\\\"";
    } elif c == '\\' {
      result = result + "\\\\";
    } elif c == '\n' {
      result = result + "\\n";
    } elif c == '\r' {
      result = result + "\\r";
    } elif c == '\t' {
      result = result + "\\t";
    } elif c == '\b' {
      result = result + "\\b";
    } elif c == '\f' {
      result = result + "\\f";
    } elif c == '/' {
      result = result + "\\/";
    } else {
      var code = c as UInt32;
      if code < 0x20 {
        result = result + "\\u00";
        result = result + convert.int_to_string(((code as Int) / 16) % 16);
        result = result + convert.int_to_string((code as Int) % 16);
      } else {
        result = result + xiom.string.str_slice(s, i, i + 1);
      }
    }
    i = i + 1;
  }
  return result;
}
