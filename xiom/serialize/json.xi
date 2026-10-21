// XIOM - Serialize: JSON
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.serialize.json

// Depends on: xiom.serialize, xiom.string, xiom.convert

// ============================================================================
// JSON parsing, stringification, tree navigation, raw format-preserving
// lookup, and typed accessors.
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
//   - json_parse caps nesting at 128 levels (Err "json_parse: nesting too
//     deep" beyond) so deeply nested untrusted payloads cannot overflow the
//     process stack.
//   - json_escape handles the standard control escapes; the backslash, quote,
//     and control characters are always escaped so output is embeddable.
//   - Number parsing accepts the JSON grammar subset (no NaN/Infinity).
// ============================================================================

use xiom.string;
use xiom.convert;
use xiom.convert.parse;
use xiom.encoding;
use xiom.collections;

/// NOTE: The parent module xiom.serialize is always present in the compile
/// unit when any xiom.serialize.* submodule is used, and it defines its own
/// `JsonValue` type (Object: Map[Str, JsonValue]). The compiler unifies the
/// two same-named types, so this module MUST use the identical enum shape
/// (Map-backed objects) or LLVM lowering fails.
pub type JsonValue = enum {
  Null,
  Bool(value: Bool),
  Number(value: Float64),
  String(value: Str),
  Array(items: Vec[JsonValue]),
  Object(entries: Map[Str, JsonValue]),
}

// ============================================================================
// Byte-level access
// ============================================================================
//
// The parser scans the raw UTF-8 bytes through a single cached (base, n)
// view of the input. string.char_at/byte_at go through runtime accessors
// that strnlen the whole string per call, and str_slice rebuilds through
// byte_at, so a char-per-byte scan costs O(n) per accessor call -- quadratic
// over a parse (relay REL-20261011-1453-xvector: 10k numbers / 49 KB parsed
// in ~2.0 s and 20k / 109 KB in ~7.6 s locally, ~4x per 2x input). JSON
// structure is ASCII, so byte comparisons are exact; string values are
// rebuilt from the raw bytes (UTF-8 passthrough).

fn _json_byte(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bounds-check against n (T007)
{
  unsafe { return *(base + i); }
}

fn _json_char(base: *UInt8, i: Int) -> Char {
  // Mask before the Char cast (wave 132b, audit): `(byte) as Int`
  // sign-extends, which would produce the wrong codepoint for bytes above
  // 0x7F (ASCII-only comparisons today, but keep the trap class out).
  return (((_json_byte(base, i)) as Int) & 0xFF) as Char;
}

fn _json_push_range(buf: &mut Vec[UInt8], base: *UInt8, start: Int, end: Int) {
  var i = start;
  while i < end {
    buf.push(_json_byte(base, i));
    i = i + 1;
  }
}

fn _json_buf_str(buf: Vec[UInt8]) -> Str {
  if buf.len() == 0 {
    return "";
  }
  return Str::from_utf8(buf);
}

// Lowercase hex digit for a nibble 0..15. Wave 126: replaces the decimal
// convert.int_to_string path, which emitted "11"/"14"/"15" for nibbles
// above 9 (a malformed five-digit \u00XYa escape for control bytes such as
// 0x0B / 0x0E / 0x1E).
fn _json_hex_digit(v: Int) -> UInt8 {
  if v < 10 {
    return (48 + v) as UInt8;
  }
  (87 + v) as UInt8
}

// Kept for the short non-hot strings (literal words, path keys); every
// big-input scan goes through the byte helpers above.
fn _json_get_char(s: Str, pos: Int) -> Char {
  var opt = xiom.string.char_at(s, pos);
  if opt.is_some { return opt.value; }
  return '\0';
}

fn _json_skip_ws(base: *UInt8, n: Int, pos: &mut Int) {
  while *pos < n {
    let c = _json_char(base, *pos);
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

/// Maximum nesting depth accepted by the parser. Untrusted input must never
/// be able to overflow the process stack: each array/object level costs
/// several stack frames here, and the observed Windows floor for this parser
/// is between 200 and 300 levels (v0.64.2), so 128 keeps a wide margin on
/// every platform (serde_json uses the same default). Deeper input returns
/// Err("json_parse: nesting too deep") instead of dying.
const _JSON_MAX_DEPTH: Int = 128;

fn _json_parse_value(base: *UInt8, n: Int, pos: &mut Int, depth: Int) -> Result[JsonValue, Str] {
  if depth >= _JSON_MAX_DEPTH {
    return Err("json_parse: nesting too deep");
  }
  _json_skip_ws(base, n, pos);
  if *pos >= n {
    return Err("json_parse: unexpected end of input");
  }
  let c = _json_char(base, *pos);
  if c == '{' { return _json_parse_object(base, n, pos, depth); }
  if c == '[' { return _json_parse_array(base, n, pos, depth); }
  if c == '"' { return _json_parse_string_val(base, n, pos); }
  if c == 't' { return _json_parse_literal(base, n, pos, "true", JsonValue.Bool(true)); }
  if c == 'f' { return _json_parse_literal(base, n, pos, "false", JsonValue.Bool(false)); }
  if c == 'n' { return _json_parse_literal(base, n, pos, "null", JsonValue.Null); }
  if c == '-' || _json_is_digit(c) { return _json_parse_number(base, n, pos); }
  return Err("json_parse: unexpected character");
}

fn _json_is_digit(c: Char) -> Bool {
  return c >= '0' && c <= '9';
}

fn _json_parse_literal(base: *UInt8, n: Int, pos: &mut Int, word: Str, val: JsonValue) -> Result[JsonValue, Str] {
  var i = 0;
  while i < word.len() {
    if *pos + i >= n {
      return Err("json_parse: unterminated literal");
    }
    let c = _json_char(base, *pos + i);
    let wc = _json_get_char(word, i);
    if c != wc {
      return Err("json_parse: invalid literal");
    }
    i = i + 1;
  }
  *pos = *pos + word.len();
  return Ok(val);
}

fn _json_parse_object(base: *UInt8, n: Int, pos: &mut Int, depth: Int) -> Result[JsonValue, Str] {
  *pos = *pos + 1;
  var entries = Map[Str, JsonValue].new();
  _json_skip_ws(base, n, pos);
  if *pos < n {
    let c = _json_char(base, *pos);
    if c == '}' {
      *pos = *pos + 1;
      return Ok(JsonValue.Object(entries));
    }
  }
  loop {
    _json_skip_ws(base, n, pos);
    if *pos >= n {
      return Err("json_parse: expected object key");
    }
    let key_result = _json_parse_string_val(base, n, pos);
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
    _json_skip_ws(base, n, pos);
    if *pos >= n {
      return Err("json_parse: expected ':'");
    }
    let colon = _json_char(base, *pos);
    if colon != ':' {
      return Err("json_parse: expected ':'");
    }
    *pos = *pos + 1;
    let value_result = _json_parse_value(base, n, pos, depth + 1);
    match value_result {
      Ok(v) => entries.insert(key, v);
      Err(e) => { return Err(e); }
    }
    _json_skip_ws(base, n, pos);
    if *pos >= n {
      return Err("json_parse: expected '}' or ','");
    }
    let next = _json_char(base, *pos);
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

fn _json_parse_array(base: *UInt8, n: Int, pos: &mut Int, depth: Int) -> Result[JsonValue, Str] {
  *pos = *pos + 1;
  var items = Vec[JsonValue].new();
  _json_skip_ws(base, n, pos);
  if *pos < n {
    let c = _json_char(base, *pos);
    if c == ']' {
      *pos = *pos + 1;
      return Ok(JsonValue.Array(items));
    }
  }
  loop {
    let value_result = _json_parse_value(base, n, pos, depth + 1);
    match value_result {
      Ok(v) => items.push(v);
      Err(e) => { return Err(e); }
    }
    _json_skip_ws(base, n, pos);
    if *pos >= n {
      return Err("json_parse: expected ']' or ','");
    }
    let next = _json_char(base, *pos);
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

fn _json_parse_string_val(base: *UInt8, n: Int, pos: &mut Int) -> Result[JsonValue, Str] {
  if *pos >= n {
    return Err("json_parse: unterminated string");
  }
  *pos = *pos + 1;
  var buf = Vec[UInt8].new();
  var start = *pos;
  loop {
    if *pos >= n {
      return Err("json_parse: unterminated string");
    }
    let b = _json_byte(base, *pos);
    if b == 34 as UInt8 {
      // closing quote
      _json_push_range(&mut buf, base, start, *pos);
      *pos = *pos + 1;
      return Ok(JsonValue.String(_json_buf_str(buf)));
    }
    if b == 92 as UInt8 {
      // backslash
      _json_push_range(&mut buf, base, start, *pos);
      *pos = *pos + 1;
      if *pos >= n {
        return Err("json_parse: unterminated escape");
      }
      let esc = _json_char(base, *pos);
      if esc == 'u' {
        *pos = *pos + 1;
        var code: Int = 0;
        var j = 0;
        while j < 4 {
          if *pos >= n {
            return Err("json_parse: unterminated unicode escape");
          }
          let hc = _json_char(base, *pos);
          var hv = _json_hex_value(hc);
          if hv < 0 {
            return Err("json_parse: invalid unicode escape");
          }
          code = code * 16 + hv;
          *pos = *pos + 1;
          j = j + 1;
        }
        // NOTE (wave 111 fix): the old branch then fell through to a shared
        // `*pos = *pos + 1`, consuming one byte PAST the 4 hex digits and
        // dropping it from the value ("a\u0042c" parsed as "aB").
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
          Ok(strv) => {
            var k = 0;
            let dln = strv.len();
            while k < dln {
              buf.push(strv.byte_at(k));
              k = k + 1;
            }
          },
          Err(_) => { buf.push(63 as UInt8); }
        }
        start = *pos;
      } else {
        if esc == '"' {
          buf.push(34 as UInt8);
        } elif esc == '\\' {
          buf.push(92 as UInt8);
        } elif esc == '/' {
          buf.push(47 as UInt8);
        } elif esc == 'b' {
          buf.push(8 as UInt8);
        } elif esc == 'f' {
          buf.push(12 as UInt8);
        } elif esc == 'n' {
          buf.push(10 as UInt8);
        } elif esc == 'r' {
          buf.push(13 as UInt8);
        } elif esc == 't' {
          buf.push(9 as UInt8);
        } else {
          return Err("json_parse: invalid escape character");
        }
        *pos = *pos + 1;
        start = *pos;
      }
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

fn _json_parse_number(base: *UInt8, n: Int, pos: &mut Int) -> Result[JsonValue, Str] {
  var start = *pos;
  if *pos < n {
    let c = _json_char(base, *pos);
    if c == '-' {
      *pos = *pos + 1;
    }
  }
  if *pos >= n {
    return Err("json_parse: expected number");
  }
  let int_start = *pos;
  while *pos < n {
    let c = _json_char(base, *pos);
    if !(_json_is_digit(c)) { break; }
    *pos = *pos + 1;
  }
  if *pos == int_start {
    return Err("json_parse: expected number");
  }
  if *pos - int_start > 1 && _json_char(base, int_start) == '0' {
    return Err("json_parse: leading zeros are not allowed");
  }
  if *pos < n {
    let c = _json_char(base, *pos);
    if c == '.' {
      *pos = *pos + 1;
      let frac_start = *pos;
      while *pos < n {
        let d = _json_char(base, *pos);
        if !(_json_is_digit(d)) { break; }
        *pos = *pos + 1;
      }
      if *pos == frac_start {
        return Err("json_parse: expected digits after decimal point");
      }
    }
  }
  if *pos < n {
    let c = _json_char(base, *pos);
    if c == 'e' || c == 'E' {
      *pos = *pos + 1;
      if *pos < n {
        let d = _json_char(base, *pos);
        if d == '+' || d == '-' {
          *pos = *pos + 1;
        }
      }
      let exp_start = *pos;
      while *pos < n {
        let d = _json_char(base, *pos);
        if !(_json_is_digit(d)) { break; }
        *pos = *pos + 1;
      }
      if *pos == exp_start {
        return Err("json_parse: expected exponent digits");
      }
    }
  }
  if *pos == start {
    return Err("json_parse: expected number");
  }
  var num_buf = Vec[UInt8].new();
  _json_push_range(&mut num_buf, base, start, *pos);
  let num_str = _json_buf_str(num_buf);
  let parsed = xiom.core.to_float_from_str(num_str);
  // NOTE: explicit `return match` -- a bare trailing match after a Vec.push
  // trips the v0.64.2 checker ("return type mismatch ... found ()").
  return match parsed {
    Ok(fv) => {
      if fv != fv { return Err("json_parse: number is not finite"); }
      if fv > 1.7976931348623157e308 || fv < -1.7976931348623157e308 {
        return Err("json_parse: number out of range");
      }
      Ok(JsonValue.Number(fv))
    }
    Err(_) => Err("json_parse: invalid number format")
  };
}

// ============================================================================
// Public API
// ============================================================================

/// Parse `s` into a JsonValue tree. Returns Err with a descriptive message
/// on malformed input or trailing garbage, and for input nested deeper than
/// the 128-level cap (`_JSON_MAX_DEPTH`).
/// Complexity: O(n), n = input length.
///
/// NOTE: the name `json_parse` collides with the parent module's own
/// json_parse and direct calls can misresolve under the current compiler
/// (BUG 25 #1). The parsing logic lives in the uniquely-named helpers above.
pub fn json_parse(s: Str) -> Result[JsonValue, Str]
  ensures: (s.len() == 0) => (result.is_err == true)
  ensures: (s == "null") => (result.is_ok == true)
{
  var pos = 0;
  let base = s.c_str();
  let n = s.len();
  let result = _json_parse_value(base, n, &pos, 0);
  match result {
    Ok(v) => {
      _json_skip_ws(base, n, &pos);
      if pos != n {
        return Err("json_parse: trailing characters after value");
      }
      return Ok(v);
    }
    Err(e) => { return Err(e); }
  }
}

/// Serialize `v` as compact JSON (no insignificant whitespace).
/// Complexity: O(n), n = number of nodes.
pub fn json_stringify(v: JsonValue) -> Str
  ensures: result.len() > 0  // every JSON value renders to at least one byte
{
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
        if f != f { return "null"; }
        if f > 1.7976931348623157e308 || f < -1.7976931348623157e308 { return "null"; }
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
pub fn json_pretty(v: JsonValue) -> Str
  ensures: result.len() > 0  // every JSON value renders to at least one byte
{
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
        if f != f { return "null"; }
        if f > 1.7976931348623157e308 || f < -1.7976931348623157e308 { return "null"; }
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
pub fn json_get_path(v: JsonValue, path: &Vec[Str]) -> Option[JsonValue]
  ensures: (path.len() == 0) => (result.is_some == true)
{
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
pub fn json_set(v: JsonValue, key: Str, value: JsonValue) -> JsonValue
  ensures: json_type(result) == "object"
{
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
pub fn json_array_push(v: JsonValue, item: JsonValue) -> JsonValue
  ensures: json_type(result) == "array"
{
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
pub fn json_object_new() -> JsonValue
  ensures: json_type(result) == "object"
{
  return JsonValue.Object(Map[Str, JsonValue].new());
}

/// In-place object builder: one Map, no copy per key. Call `build()` to
/// return a JsonValue. Avoids the O(n^2) copy churn of `json_set`.
pub type JsonObjectBuilder = { entries: Map[Str, JsonValue]; }

/// New empty JSON object builder.
pub fn json_object_builder_new() -> JsonObjectBuilder
  ensures: result.entries.len() == 0
{
  return JsonObjectBuilder{ entries: Map[Str, JsonValue].new() };
}

/// Insert or replace one key in the object builder.
pub fn JsonObjectBuilder.put(&mut self, key: Str, value: JsonValue)
  ensures: self.entries.contains(&key)
{
  self.entries.insert(key, value);
}

/// Wrap the object builder's entries as a JSON object.
pub fn JsonObjectBuilder.build(self) -> JsonValue
  ensures: json_type(result) == "object"
{
  return JsonValue.Object(self.entries);
}

/// In-place array builder: one Vec, no copy per item.
pub type JsonArrayBuilder = { items: Vec[JsonValue]; }

/// New empty JSON array builder.
pub fn json_array_builder_new() -> JsonArrayBuilder
  ensures: result.items.len() == 0
{
  return JsonArrayBuilder{ items: Vec[JsonValue].new() };
}

/// Append one item to the array builder.
pub fn JsonArrayBuilder.push(&mut self, item: JsonValue)
  ensures: self.items.len() >= 1
{
  self.items.push(item);
}

/// Wrap the array builder's items as a JSON array.
pub fn JsonArrayBuilder.build(self) -> JsonValue
  ensures: json_type(result) == "array"
{
  return JsonValue.Array(self.items);
}

/// A new empty JSON array.
/// Complexity: O(1).
pub fn json_array_new() -> JsonValue
  ensures: json_type(result) == "array"
{
  return JsonValue.Array(Vec[JsonValue].new());
}

/// Wrap a float as a JSON number.
/// Complexity: O(1).
pub fn json_number(f: Float64) -> JsonValue
  ensures: json_type(result) == "number"
{
  return JsonValue.Number(f);
}

/// Wrap a string as a JSON string.
/// Complexity: O(1).
pub fn json_string(s: Str) -> JsonValue
  ensures: json_type(result) == "string"
{
  return JsonValue.String(s);
}

/// Wrap a bool as a JSON bool.
/// Complexity: O(1).
pub fn json_bool(b: Bool) -> JsonValue
  ensures: json_type(result) == "bool"
{
  return JsonValue.Bool(b);
}

/// The JSON null value.
/// Complexity: O(1).
pub fn json_null() -> JsonValue
  ensures: json_type(result) == "null"
{
  return JsonValue.Null;
}

/// The type name of `v`: object, array, string, number, bool, or null.
/// Complexity: O(1).
pub fn json_type(v: JsonValue) -> Str
  ensures: result.len() >= 4
{
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
pub fn json_escape(s: Str) -> Str
  ensures: (s.len() == 0) => (result == "")
  ensures: result.len() >= s.len()
{
  return _json_escape_impl(s);
}

fn _json_escape_impl(s: Str) -> Str {
  var out: Vec[UInt8] = Vec[UInt8].new();
  let n = s.len();
  let base = s.c_str();
  var i = 0;
  while i < n {
    let b = _json_byte(base, i);
    if b == 34 {
      out.push(92);
      out.push(34);
    } elif b == 92 {
      out.push(92);
      out.push(92);
    } elif b == 10 {
      out.push(92);
      out.push(110);
    } elif b == 13 {
      out.push(92);
      out.push(114);
    } elif b == 9 {
      out.push(92);
      out.push(116);
    } elif b == 8 {
      out.push(92);
      out.push(98);
    } elif b == 12 {
      out.push(92);
      out.push(102);
    } elif b == 47 {
      out.push(92);
      out.push(47);
    } else {
      if b < 0x20 {
        out.push(92);
        out.push(117);
        out.push(48);
        out.push(48);
        out.push(_json_hex_digit((b as Int) >> 4));
        out.push(_json_hex_digit((b as Int) & 0x0F));
      } else {
        out.push(b);
      }
    }
    i = i + 1;
  }
  return _json_buf_str(out);
}

// ============================================================================
// Raw, format-preserving lookup and typed accessors (wave 169)
//
// The packages wishlist (2026-10-02, requesters nats/oauth/dynamo/keymgmt/
// vault/elastic/cloudlog) asked for a raw-byte, format-preserving JSON member
// lookup with boundary-checked key spans, scalar values, member offsets, and
// byte-offset errors -- the DOM parser above is lossy for that use (float
// reformatting, key order, duplicate keys). This surface scans the original
// bytes:
//   - json_find_member: the first top-level member with the asked key, with
//     the raw key span and the exact value byte span (offsets into `s`);
//   - json_raw_get: the raw value bytes, untouched (strings keep their
//     quotes and escapes; numbers keep their formatting);
//   - json_raw_get_str: the decoded value of a string member (escape-aware,
//     surrogate pairs combined, lone surrogates rejected -- keymgmt);
//   - json_raw_get_int: the value of a flat integer member (vault/dynamo),
//     range-checked;
//   - json_as_str/bool/int/float: typed DOM accessors.
//
// Safety: the scanner is iterative and bounded (one pass over the member
// list; value spans are scanned once, bracket-balanced, string-aware);
// malformed input returns a typed Err carrying the byte offset. Nested
// container values are bracket/string balanced only -- deep token validation
// stays json_parse's job (documented). Duplicate keys: the first match wins.
// ============================================================================

/// Offsets of one object member in the source bytes: [key_start, key_end) is
/// the raw key text without its quotes; [value_start, value_end) is the exact
/// raw value (a string member includes its quotes and escape bytes).
pub type JsonMemberSpan = {
  key_start: Int;
  key_end: Int;
  value_start: Int;
  value_end: Int;
}

fn _json_raw_err(msg: Str, off: Int) -> Str {
  return msg + " at byte " + convert.int_to_string(off);
}

fn _json_range_str(base: *UInt8, start: Int, end: Int) -> Str {
  if end <= start {
    return "";
  }
  var buf = Vec[UInt8].new();
  _json_push_range(&mut buf, base, start, end);
  return _json_buf_str(buf);
}

// UTF-8 encode a JSON-decoded code point (0..0x10FFFF, surrogates excluded by
// the callers). Control characters are legal inside JSON strings.
fn _json_encode_cp(cp: Int, buf: &mut Vec[UInt8]) -> Bool {
  if cp < 0 || cp > 0x10FFFF { return false; }
  if cp >= 0xD800 && cp <= 0xDFFF { return false; }
  if cp < 0x80 {
    buf.push(cp as UInt8);
    return true;
  }
  if cp < 0x800 {
    buf.push((0xC0 | (cp >> 6)) as UInt8);
    buf.push((0x80 | (cp & 0x3F)) as UInt8);
    return true;
  }
  if cp < 0x10000 {
    buf.push((0xE0 | (cp >> 12)) as UInt8);
    buf.push((0x80 | ((cp >> 6) & 0x3F)) as UInt8);
    buf.push((0x80 | (cp & 0x3F)) as UInt8);
    return true;
  }
  buf.push((0xF0 | (cp >> 18)) as UInt8);
  buf.push((0x80 | ((cp >> 12) & 0x3F)) as UInt8);
  buf.push((0x80 | ((cp >> 6) & 0x3F)) as UInt8);
  buf.push((0x80 | (cp & 0x3F)) as UInt8);
  return true;
}

// Validate one string token and advance *pos past its closing quote.
fn _json_raw_scan_string(base: *UInt8, n: Int, pos: &mut Int) -> Result[Bool, Str] {
  let start = *pos;
  *pos = *pos + 1;
  while *pos < n {
    let b = _json_byte(base, *pos);
    if b == 34 {  // closing quote
      *pos = *pos + 1;
      return Ok(true);
    }
    if b == 92 {  // backslash
      *pos = *pos + 1;
      if *pos >= n {
        return Err(_json_raw_err("json: unterminated escape", start));
      }
      let e = _json_char(base, *pos);
      if e == 'u' {
        var k = 0;
        while k < 4 {
          let hp = *pos + 1 + k;
          if hp >= n {
            return Err(_json_raw_err("json: unterminated unicode escape", start));
          }
          if _json_hex_value(_json_char(base, hp)) < 0 {
            return Err(_json_raw_err("json: invalid unicode escape", hp));
          }
          k = k + 1;
        }
        *pos = *pos + 5;
      } elif e == '"' || e == '\\' || e == '/' || e == 'b' || e == 'f' || e == 'n' || e == 'r' || e == 't' {
        *pos = *pos + 1;
      } else {
        return Err(_json_raw_err("json: invalid escape", *pos - 1));
      }
    } elif b < 0x20 {
      return Err(_json_raw_err("json: raw control character in string", *pos));
    } else {
      *pos = *pos + 1;
    }
  }
  return Err(_json_raw_err("json: unterminated string", start));
}

// Scan one number token (JSON grammar, no conversion).
fn _json_raw_scan_number(base: *UInt8, n: Int, pos: &mut Int) -> Result[Bool, Str] {
  let start = *pos;
  if *pos < n && _json_char(base, *pos) == '-' {
    *pos = *pos + 1;
  }
  if *pos >= n {
    return Err(_json_raw_err("json: expected number", *pos));
  }
  let int_start = *pos;
  while *pos < n && _json_is_digit(_json_char(base, *pos)) {
    *pos = *pos + 1;
  }
  if *pos == int_start {
    return Err(_json_raw_err("json: expected number", *pos));
  }
  if *pos - int_start > 1 && _json_char(base, int_start) == '0' {
    return Err(_json_raw_err("json: leading zeros are not allowed", int_start));
  }
  if *pos < n && _json_char(base, *pos) == '.' {
    *pos = *pos + 1;
    let frac_start = *pos;
    while *pos < n && _json_is_digit(_json_char(base, *pos)) {
      *pos = *pos + 1;
    }
    if *pos == frac_start {
      return Err(_json_raw_err("json: expected digits after decimal point", *pos));
    }
  }
  if *pos < n {
    let c = _json_char(base, *pos);
    if c == 'e' || c == 'E' {
      *pos = *pos + 1;
      if *pos < n {
        let d = _json_char(base, *pos);
        if d == '+' || d == '-' {
          *pos = *pos + 1;
        }
      }
      let exp_start = *pos;
      while *pos < n && _json_is_digit(_json_char(base, *pos)) {
        *pos = *pos + 1;
      }
      if *pos == exp_start {
        return Err(_json_raw_err("json: expected exponent digits", *pos));
      }
    }
  }
  if *pos == start {
    return Err(_json_raw_err("json: expected number", *pos));
  }
  return Ok(true);
}

// Byte-exact literal match and advance (true/false/null).
fn _json_raw_expect(base: *UInt8, n: Int, pos: &mut Int, word: Str) -> Result[Bool, Str] {
  let start = *pos;
  var i = 0;
  while i < word.len() {
    if start + i >= n {
      return Err(_json_raw_err("json: unterminated literal", start));
    }
    if _json_char(base, start + i) != _json_get_char(word, i) {
      return Err(_json_raw_err("json: invalid literal", start));
    }
    i = i + 1;
  }
  *pos = start + word.len();
  return Ok(true);
}

// Scan one value token and advance past it. Strings and numbers are
// validated; containers are bracket-balanced and string-aware (deep token
// validation stays json_parse's job).
fn _json_raw_scan_value(base: *UInt8, n: Int, pos: &mut Int) -> Result[Bool, Str] {
  if *pos >= n {
    return Err(_json_raw_err("json: expected value", *pos));
  }
  let c = _json_char(base, *pos);
  if c == '"' {
    return _json_raw_scan_string(base, n, pos);
  }
  if c == '{' || c == '[' {
    let start = *pos;
    var depth = 0;
    while *pos < n {
      let b = _json_byte(base, *pos);
      if b == 34 {
        match _json_raw_scan_string(base, n, pos) {
          Ok(_) => {},
          Err(e) => { return Err(e); },
        }
        continue;
      }
      if b == 123 || b == 91 {  // { [
        depth = depth + 1;
        *pos = *pos + 1;
        continue;
      }
      if b == 125 || b == 93 {  // } ]
        depth = depth - 1;
        *pos = *pos + 1;
        if depth == 0 {
          return Ok(true);
        }
        continue;
      }
      *pos = *pos + 1;
    }
    return Err(_json_raw_err("json: unterminated value", start));
  }
  if c == 't' { return _json_raw_expect(base, n, pos, "true"); }
  if c == 'f' { return _json_raw_expect(base, n, pos, "false"); }
  if c == 'n' { return _json_raw_expect(base, n, pos, "null"); }
  if c == '-' || _json_is_digit(c) {
    return _json_raw_scan_number(base, n, pos);
  }
  return Err(_json_raw_err("json: unexpected character", *pos));
}

// Decode a string-token body (the bytes between the quotes) to its Str
// value. Escape-aware; surrogate pairs are combined and lone surrogates are
// rejected.
fn _json_decode_string_range(base: *UInt8, start: Int, end: Int) -> Result[Str, Str] {
  var buf = Vec[UInt8].new();
  var i = start;
  while i < end {
    let b = _json_byte(base, i);
    if b == 92 {
      if i + 1 >= end {
        return Err(_json_raw_err("json: unterminated escape", i));
      }
      let e = _json_char(base, i + 1);
      if e == '"' {
        buf.push(34);
        i = i + 2;
      } elif e == '\\' {
        buf.push(92);
        i = i + 2;
      } elif e == '/' {
        buf.push(47);
        i = i + 2;
      } elif e == 'b' {
        buf.push(8);
        i = i + 2;
      } elif e == 'f' {
        buf.push(12);
        i = i + 2;
      } elif e == 'n' {
        buf.push(10);
        i = i + 2;
      } elif e == 'r' {
        buf.push(13);
        i = i + 2;
      } elif e == 't' {
        buf.push(9);
        i = i + 2;
      } elif e == 'u' {
        if i + 5 >= end {
          return Err(_json_raw_err("json: truncated unicode escape", i));
        }
        var cp = 0;
        var k = 0;
        while k < 4 {
          let hv = _json_hex_value(_json_char(base, i + 2 + k));
          if hv < 0 {
            return Err(_json_raw_err("json: invalid unicode escape", i));
          }
          cp = cp * 16 + hv;
          k = k + 1;
        }
        var adv = 6;
        if cp >= 0xD800 && cp <= 0xDBFF {
          if i + 11 >= end {
            return Err(_json_raw_err("json: lone surrogate", i));
          }
          if _json_char(base, i + 6) != '\\' || _json_char(base, i + 7) != 'u' {
            return Err(_json_raw_err("json: lone surrogate", i));
          }
          var lo = 0;
          var m = 0;
          while m < 4 {
            let hv2 = _json_hex_value(_json_char(base, i + 8 + m));
            if hv2 < 0 {
              return Err(_json_raw_err("json: invalid unicode escape", i + 6));
            }
            lo = lo * 16 + hv2;
            m = m + 1;
          }
          if lo < 0xDC00 || lo > 0xDFFF {
            return Err(_json_raw_err("json: lone surrogate", i));
          }
          cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00);
          adv = 12;
        } elif cp >= 0xDC00 && cp <= 0xDFFF {
          return Err(_json_raw_err("json: lone surrogate", i));
        }
        if !_json_encode_cp(cp, &mut buf) {
          return Err(_json_raw_err("json: invalid code point", i));
        }
        i = i + adv;
      } else {
        return Err(_json_raw_err("json: invalid escape", i));
      }
    } elif b < 0x20 {
      return Err(_json_raw_err("json: raw control character in string", i));
    } else {
      buf.push(b);
      i = i + 1;
    }
  }
  return Ok(_json_buf_str(buf));
}

// The first top-level object member named `key` (escape-aware key compare,
// first match wins). The value span is scanned once: strings/numbers are
// validated, containers are bracket-balanced and string-aware.
fn _json_find_member_impl(base: *UInt8, n: Int, key: Str) -> Result[JsonMemberSpan, Str] {
  var pos = 0;
  _json_skip_ws(base, n, &pos);
  if pos >= n {
    return Err(_json_raw_err("json_find_member: empty input", pos));
  }
  if _json_char(base, pos) != '{' {
    return Err(_json_raw_err("json_find_member: input is not an object", pos));
  }
  pos = pos + 1;
  _json_skip_ws(base, n, &pos);
  if pos < n && _json_char(base, pos) == '}' {
    return Err(_json_raw_err("json_find_member: key not found", pos));
  }
  loop {
    _json_skip_ws(base, n, &pos);
    if pos >= n {
      return Err(_json_raw_err("json_find_member: expected key", pos));
    }
    if _json_char(base, pos) != '"' {
      return Err(_json_raw_err("json_find_member: expected string key", pos));
    }
    let kq = pos;
    match _json_raw_scan_string(base, n, &pos) {
      Ok(_) => {},
      Err(e) => { return Err(e); },
    }
    let key_close = pos - 1;
    _json_skip_ws(base, n, &pos);
    if pos >= n || _json_char(base, pos) != ':' {
      return Err(_json_raw_err("json_find_member: expected ':'", pos));
    }
    pos = pos + 1;
    _json_skip_ws(base, n, &pos);
    if pos >= n {
      return Err(_json_raw_err("json_find_member: missing value", pos));
    }
    let vstart = pos;
    match _json_raw_scan_value(base, n, &pos) {
      Ok(_) => {},
      Err(e) => { return Err(e); },
    }
    var matched = false;
    match _json_decode_string_range(base, kq + 1, key_close) {
      Ok(k) => {
        if k == key { matched = true; }
      },
      Err(e) => { return Err(e); },
    }
    if matched {
      return Ok(JsonMemberSpan{ key_start: kq + 1; key_end: key_close; value_start: vstart; value_end: pos; });
    }
    _json_skip_ws(base, n, &pos);
    if pos >= n {
      return Err(_json_raw_err("json_find_member: expected ',' or '}'", pos));
    }
    let c = _json_char(base, pos);
    if c == '}' {
      return Err(_json_raw_err("json_find_member: key not found", pos));
    }
    if c != ',' {
      return Err(_json_raw_err("json_find_member: expected ',' or '}'", pos));
    }
    pos = pos + 1;
  }
  return Err(_json_raw_err("json_find_member: unexpected end of object", pos));
}

// ============================================================================
// Public raw lookup + typed accessors
// ============================================================================

/// Locate the first member named `key` in the top-level object of `s` and
/// return its raw spans (offsets into `s`). Escape-aware key compare;
/// malformed input yields a typed Err with the byte offset. Nested container
/// values are bracket/string balanced (deep validation stays json_parse's
/// job); duplicate keys report the first match.
/// Complexity: O(n), n = bytes scanned up to the match.
pub fn json_find_member(s: Str, key: Str) -> Result[JsonMemberSpan, Str]
  ensures: (s.len() == 0) => (result.is_err == true)
{
  let base = s.c_str();
  let n = s.len();
  return _json_find_member_impl(base, n, key);
}

/// The exact raw value bytes of the first member named `key`, untouched by
/// parsing (a string member keeps its quotes and escape bytes; a number keeps
/// its formatting) -- the format-preserving lookup the packages relay asked
/// for.
/// Complexity: O(n), n = bytes scanned up to the match.
pub fn json_raw_get(s: Str, key: Str) -> Result[Str, Str]
  ensures: (s.len() == 0) => (result.is_err == true)
{
  match json_find_member(s, key) {
    Ok(m) => {
      return Ok(_json_range_str(s.c_str(), m.value_start, m.value_end));
    },
    Err(e) => { return Err(e); },
  }
}

/// The decoded value of a string member named `key` (escape-aware; surrogate
/// pairs are combined, lone surrogates are rejected). Err when the member is
/// missing, is not a string, or the member list is malformed.
/// Complexity: O(n), n = bytes scanned up to and through the match.
pub fn json_raw_get_str(s: Str, key: Str) -> Result[Str, Str]
  ensures: (s.len() == 0) => (result.is_err == true)
{
  match json_find_member(s, key) {
    Ok(m) => {
      let base = s.c_str();
      if m.value_end - m.value_start < 2 {
        return Err("json_raw_get_str: value is not a string");
      }
      if _json_char(base, m.value_start) != '"' || _json_char(base, m.value_end - 1) != '"' {
        return Err("json_raw_get_str: value is not a string");
      }
      return _json_decode_string_range(base, m.value_start + 1, m.value_end - 1);
    },
    Err(e) => { return Err(e); },
  }
}

/// The value of an integer member named `key`. The raw token must be an
/// optional '-' followed by ASCII digits (JSON integers, no fraction or
/// exponent -- the flat-scanner shape vault/dynamo asked for); the parsed
/// value is range-checked against Int.
/// Complexity: O(n), n = bytes scanned up to and through the match.
pub fn json_raw_get_int(s: Str, key: Str) -> Result[Int, Str]
  ensures: (s.len() == 0) => (result.is_err == true)
{
  match json_find_member(s, key) {
    Ok(m) => {
      let base = s.c_str();
      var i = m.value_start;
      if i < m.value_end && _json_char(base, i) == '-' {
        i = i + 1;
      }
      if i >= m.value_end {
        return Err("json_raw_get_int: value is not an integer");
      }
      while i < m.value_end {
        if !_json_is_digit(_json_char(base, i)) {
          return Err("json_raw_get_int: value is not an integer");
        }
        i = i + 1;
      }
      let token = _json_range_str(base, m.value_start, m.value_end);
      match parse.parse_int(token) {
        Ok(v) => { return Ok(v); },
        Err(_) => { return Err("json_raw_get_int: integer out of range"); },
      }
    },
    Err(e) => { return Err(e); },
  }
}

/// The Str payload of a JSON string value (None for every other type).
/// Complexity: O(1).
pub fn json_as_str(v: JsonValue) -> Option[Str]
  ensures: (result.is_some == true) => (json_type(v) == "string")
{
  match v {
    JsonValue.String(s) => { return Some(s); },
    _ => { return None; },
  }
}

/// The Bool payload of a JSON bool value (None for every other type).
/// Complexity: O(1).
pub fn json_as_bool(v: JsonValue) -> Option[Bool]
  ensures: (result.is_some == true) => (json_type(v) == "bool")
{
  match v {
    JsonValue.Bool(b) => { return Some(b); },
    _ => { return None; },
  }
}

/// The Int payload of a JSON number when it is exactly integer-valued and
/// within +/-2^53 (None for non-numbers, fractional values, NaN, and unsafe
/// magnitudes). The double bound keeps the conversion exact.
/// Complexity: O(1).
pub fn json_as_int(v: JsonValue) -> Option[Int]
  ensures: (result.is_some == true) => (json_type(v) == "number")
{
  match v {
    JsonValue.Number(f) => {
      if f != f { return None; }
      if f < -9007199254740992.0 || f > 9007199254740992.0 { return None; }
      let i = f as Int;
      if (i as Float64) == f { return Some(i); }
      return None;
    },
    _ => { return None; },
  }
}

/// The Float64 payload of a JSON number (None for every other type).
/// Complexity: O(1).
pub fn json_as_float(v: JsonValue) -> Option[Float64]
  ensures: (result.is_some == true) => (json_type(v) == "number")
{
  match v {
    JsonValue.Number(f) => { return Some(f); },
    _ => { return None; },
  }
}
