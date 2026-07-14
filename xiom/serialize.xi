// XIOM — Serialization Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// derive[Serialize, Deserialize] with contract preservation.
// A deserialized struct is validated against its invariants.

module xiom.serialize

use xiom.collections;
use xiom.convert;

// === Serialize trait ===
pub interface Serialize {
  fn serialize(self) -> Result[Str, SerializeError];
  fn serialize_json(self) -> Result[Str, SerializeError];
  fn serialize_bytes(self) -> Result[Vec[UInt8], SerializeError];
}

// === Deserialize trait (with contract preservation) ===
pub interface Deserialize {
  fn deserialize(data: Str) -> Result[Self, SerializeError]
    ensures: result is Ok => self.invariant_check()
  fn deserialize_json(data: Str) -> Result[Self, SerializeError]
    ensures: result is Ok => self.invariant_check()
  fn deserialize_bytes(data: Vec[UInt8]) -> Result[Self, SerializeError]
    ensures: result is Ok => self.invariant_check()
}

// === Error type ===
pub type SerializeError = {
  kind: Int;
  message: Str;
  path: Str;
  line: Int;
  col: Int;
} derive[Eq, Clone, Display]

// Error kinds: 0=Unknown, 1=InvalidFormat, 2=MissingField, 3=TypeMismatch, 4=ContractViolation, 5=UnsupportedType

pub fn SerializeError.format_error() -> Str {
  var s = "SerializeError[";
  s = s + convert.int_to_string(self.kind);
  s = s + "]: ";
  s = s + self.message;
  if self.path != "" {
    s = s + " at " + self.path;
  }
  s = s + " (line " + convert.int_to_string(self.line);
  s = s + ", col " + convert.int_to_string(self.col) + ")";
  return s;
}

// === Format detection ===
pub fn detect_format(data: &Vec[UInt8]) -> Str {
  if data.len() == 0 {
    return "unknown";
  }
  let first = data[0];
  if first == 123 || first == 91 || first == 34 {
    return "json";
  }
  return "binary";
}

pub fn is_valid_json(data: Str) -> Bool {
  let result = json_parse(data);
  result.is_ok
}

pub fn is_valid_bytes(data: &Vec[UInt8]) -> Bool {
  return true;
}

// === JSON helpers ===
pub fn json_string(s: Str) -> Str {
  var result = "\"";
  let len = s.len();
  var i: Int = 0;
  while i < len {
    let c = s.char_at(i);
    if c == '\"' {
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
    } else {
      result = result + xiom.string.str_slice(s, i, i + 1);
    }
    i = i + 1;
  }
  result = result + "\"";
  return result;
}

pub fn json_number(n: Float64) -> Str {
  return convert.float_to_string(n);
}

pub fn json_bool(b: Bool) -> Str {
  if b { return "true"; }
  return "false";
}

pub fn json_null() -> Str {
  return "null";
}

pub fn json_array(items: Vec[Str]) -> Str {
  var result = "[";
  var i: Int = 0;
  while i < items.len() {
    if i > 0 {
      result = result + ", ";
    }
    result = result + items[i];
    i = i + 1;
  }
  result = result + "]";
  return result;
}

pub fn json_object(pairs: Vec[(Str, Str)]) -> Str {
  var result = "{";
  var i: Int = 0;
  while i < pairs.len() {
    if i > 0 {
      result = result + ", ";
    }
    let (key, val) = pairs[i];
    result = result + json_string(key);
    result = result + ": ";
    result = result + val;
    i = i + 1;
  }
  result = result + "}";
  return result;
}

pub fn to_json[T: Serialize](value: T) -> Result[Str, SerializeError] {
  return value.serialize_json();
}

pub fn from_json[T: Deserialize](s: Str) -> Result[T, SerializeError] {
  return T.deserialize_json(s);
}

// === JSON Parser ===

fn make_serror(msg: Str, pos: Int) -> SerializeError {
  return SerializeError {
    kind: 1;
    message: msg;
    path: "";
    line: 0;
    col: pos;
  };
}

fn skip_whitespace(s: Str, pos: &mut Int) {
  while *pos < s.len() {
    let opt = xiom.string.char_at(s, *pos);
    if !(opt.is_some) { break; }
    let c = opt.value;
    if !(xiom.char.is_whitespace(c)) {
      break;
    }
    *pos = *pos + 1;
  }
}

fn parse_value(s: Str, pos: &mut Int) -> Result[JsonValue, SerializeError] {
  let opt = xiom.string.char_at(s, *pos);
  match opt {
    Some('{') => parse_object(s, pos);
    Some('[') => parse_array(s, pos);
    Some('"') => parse_string_val(s, pos);
    Some('t') | Some('f') => parse_bool(s, pos);
    Some('n') => parse_null(s, pos);
    Some(c) => {
      if c == '-' || xiom.char.is_digit(c) {
        parse_number(s, pos)
      } else {
        Err(make_serror("unexpected character", *pos))
      }
    };
    None => Err(make_serror("unexpected end of input", *pos));
  }
}

fn parse_object(s: Str, pos: &mut Int) -> Result[JsonValue, SerializeError] {
  *pos = *pos + 1;
  var map = Map[Str, JsonValue].new();
  skip_whitespace(s, pos);
  if *pos < s.len() {
    let opt = xiom.string.char_at(s, *pos);
    if opt.is_some && opt.value == '}' {
      *pos = *pos + 1;
      return Ok(JsonValue.Object(map));
    }
  }
  loop {
    skip_whitespace(s, pos);
    let key_result = parse_string_val(s, pos)?;
    let key = match key_result {
      JsonValue.String(k) => k;
      _ => { return Err(make_serror("expected string key", *pos)); };
    };
    skip_whitespace(s, pos);
    if *pos >= s.len() {
      return Err(make_serror("expected ':'", *pos));
    }
    let opt_colon = xiom.string.char_at(s, *pos);
    if !(opt_colon.is_some) || opt_colon.value != ':' {
      return Err(make_serror("expected ':'", *pos));
    }
    *pos = *pos + 1;
    skip_whitespace(s, pos);
    let value = parse_value(s, pos)?;
    map.insert(key, value);
    skip_whitespace(s, pos);
    if *pos >= s.len() {
      return Err(make_serror("expected '}' or ','", *pos));
    }
    let opt_next = xiom.string.char_at(s, *pos);
    if opt_next.is_some && opt_next.value == '}' {
      *pos = *pos + 1;
      break;
    }
    if opt_next.is_some && opt_next.value == ',' {
      *pos = *pos + 1;
    } else {
      return Err(make_serror("expected '}' or ','", *pos));
    }
  }
  return Ok(JsonValue.Object(map));
}

fn parse_array(s: Str, pos: &mut Int) -> Result[JsonValue, SerializeError] {
  *pos = *pos + 1;
  var items = Vec[JsonValue].new();
  skip_whitespace(s, pos);
  if *pos < s.len() {
    let opt = xiom.string.char_at(s, *pos);
    if opt.is_some && opt.value == ']' {
      *pos = *pos + 1;
      return Ok(JsonValue.Array(items));
    }
  }
  loop {
    skip_whitespace(s, pos);
    let value = parse_value(s, pos)?;
    items.push(value);
    skip_whitespace(s, pos);
    if *pos >= s.len() {
      return Err(make_serror("expected ']' or ','", *pos));
    }
    let opt_next = xiom.string.char_at(s, *pos);
    if opt_next.is_some && opt_next.value == ']' {
      *pos = *pos + 1;
      break;
    }
    if opt_next.is_some && opt_next.value == ',' {
      *pos = *pos + 1;
    } else {
      return Err(make_serror("expected ']' or ','", *pos));
    }
  }
  return Ok(JsonValue.Array(items));
}

fn parse_string_val(s: Str, pos: &mut Int) -> Result[JsonValue, SerializeError] {
  *pos = *pos + 1;
  var result = "";
  var start = *pos;
  loop {
    if *pos >= s.len() {
      return Err(make_serror("unterminated string", start));
    }
    let c = s.char_at(*pos);
    if c == '\"' {
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
        return Err(make_serror("unterminated escape", *pos));
      }
      let esc = s.char_at(*pos);
      if esc == '\"' {
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
        result = result + "?";
        *pos = *pos + 4;
      } else {
        return Err(make_serror("invalid escape character", *pos));
      }
      *pos = *pos + 1;
      start = *pos;
    } else {
      *pos = *pos + 1;
    }
  }
}

fn parse_bool(s: Str, pos: &mut Int) -> Result[JsonValue, SerializeError] {
  if *pos + 4 <= s.len() && xiom.string.str_slice(s, *pos, *pos + 4) == "true" {
    *pos = *pos + 4;
    return Ok(JsonValue.Bool(true));
  }
  if *pos + 5 <= s.len() && xiom.string.str_slice(s, *pos, *pos + 5) == "false" {
    *pos = *pos + 5;
    return Ok(JsonValue.Bool(false));
  }
  return Err(make_serror("invalid boolean literal", *pos));
}

fn parse_null(s: Str, pos: &mut Int) -> Result[JsonValue, SerializeError] {
  if *pos + 4 <= s.len() && xiom.string.str_slice(s, *pos, *pos + 4) == "null" {
    *pos = *pos + 4;
    return Ok(JsonValue.Null);
  }
  return Err(make_serror("invalid null literal", *pos));
}

fn parse_number(s: Str, pos: &mut Int) -> Result[JsonValue, SerializeError] {
  let start = *pos;
  if *pos < s.len() {
    let c = s.char_at(*pos);
    if c == '-' {
      *pos = *pos + 1;
    }
  }
  if *pos >= s.len() {
    return Err(make_serror("expected number", *pos));
  }
  while *pos < s.len() {
    let c = s.char_at(*pos);
    if !(xiom.char.is_digit(c)) { break; }
    *pos = *pos + 1;
  }
  if *pos < s.len() {
    let c = s.char_at(*pos);
    if c == '.' {
      *pos = *pos + 1;
      while *pos < s.len() {
        let d = s.char_at(*pos);
        if !(xiom.char.is_digit(d)) { break; }
        *pos = *pos + 1;
      }
    }
  }
  if *pos < s.len() {
    let c = s.char_at(*pos);
    if c == 'e' || c == 'E' {
      *pos = *pos + 1;
      if *pos < s.len() {
        let d = s.char_at(*pos);
        if d == '+' || d == '-' {
          *pos = *pos + 1;
        }
      }
      while *pos < s.len() {
        let d = s.char_at(*pos);
        if !(xiom.char.is_digit(d)) { break; }
        *pos = *pos + 1;
      }
    }
  }
  if *pos == start {
    return Err(make_serror("expected number", *pos));
  }
  let num_str = xiom.string.str_slice(s, start, *pos);
  let parsed = xiom.core.to_float_from_str(num_str);
  match parsed {
    Ok(n) => Ok(JsonValue.Number(n));
    Err(_) => Err(make_serror("invalid number format", start));
  }
}

pub fn json_parse(data: Str) -> Result[JsonValue, SerializeError] {
  var pos = 0;
  skip_whitespace(data, &pos);
  if pos >= data.len() {
    return Err(make_serror("empty input", 0));
  }
  let result = parse_value(data, &pos)?;
  skip_whitespace(data, &pos);
  if pos != data.len() {
    return Err(make_serror("trailing characters", pos));
  }
  return Ok(result);
}

pub fn parse_json(s: Str) -> Result[JsonValue, SerializeError] {
  return json_parse(s);
}

pub type JsonValue = enum {
  Null,
  Bool(value: Bool),
  Number(value: Float64),
  String(value: Str),
  Array(items: Vec<JsonValue>),
  Object(entries: Map[Str, JsonValue]),
}

// === JsonValue methods ===

pub fn JsonValue.to_str(self) -> Str {
  match self {
    Null => { return "null"; };
    Bool(v) => {
      if v { return "true"; }
      return "false";
    };
    Number(v) => { return convert.float_to_string(v); };
    String(v) => {
      var s = "\"";
      s = s + v;
      s = s + "\"";
      return s;
    };
    Array(items) => {
      var s = "[";
      var i: Int = 0;
      while i < items.len() {
        if i > 0 { s = s + ", "; }
        s = s + items[i].to_str();
        i = i + 1;
      }
      s = s + "]";
      return s;
    };
    Object(entries) => {
      var s = "{";
      var i: Int = 0;
      while i < entries.keys.len() {
        if i > 0 { s = s + ", "; }
        s = s + json_string(entries.keys[i]);
        s = s + ": ";
        s = s + entries.values[i].to_str();
        i = i + 1;
      }
      s = s + "}";
      return s;
    };
  }
}

pub fn JsonValue.get(self, key: Str) -> Option[JsonValue] {
  match self {
    Object(entries) => {
      var i: Int = 0;
      while i < entries.keys.len() {
        if entries.keys[i] == key { return Some(entries.values[i]); }
        i = i + 1;
      }
      return None;
    };
    _ => None;
  }
}

pub fn JsonValue.index(self, i: Int) -> Option[JsonValue] {
  match self {
    Array(items) => {
      if i < 0 || i >= items.len() { return None; }
      return Some(items[i]);
    };
    _ => None;
  }
}

// === Binary helpers ===
pub fn little_endian() -> Bool {
  return true;
}

pub fn big_endian() -> Bool {
  return false;
}
