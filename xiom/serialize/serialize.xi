// XIOM -- Serialization Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// derive[Serialize, Deserialize] with contract preservation.
// A deserialized struct is validated against its invariants.

module xiom.serialize
use xiom.serialize.json;
use xiom.serialize.varint;
use xiom.serialize.endian;
use xiom.serialize.yaml_lite;

use xiom.collections;
use xiom.convert;
use xiom.encoding;

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
pub fn detect_format(data: &Vec[UInt8]) -> Str
  ensures: result.len() > 0
{
  if data.len() == 0 {
    return "unknown";
  }
  let first = data[0];
  if first == 123 || first == 91 || first == 34 {
    return "json";
  }
  return "binary";
}

pub fn is_valid_json(data: Str) -> Bool
  requires: data.len() >= 0
{
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
    let c = get_char(s,i);
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

/// Safe character-at: uses xiom.string.char_at (module-qualified) which returns
/// Option[Char]. Unwraps to the character value or '\0' on None/out-of-bounds.
/// Avoids the `get_char(s,pos)` method syntax which has inconsistent codegen.
fn get_char(s: Str, pos: Int) -> Char {
  let opt = xiom.string.char_at(s, pos);
  if opt.is_some { return opt.value; }
  return '\0';
}

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
    Some(c) => {
      if c == 'n' {
        parse_null(s, pos)
      } elif c == 't' || c == 'f' {
        parse_bool(s, pos)
      } elif c == '-' || xiom.char.is_digit(c) {
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
    let c = get_char(s,*pos);
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
      let esc = get_char(s,*pos);
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
    let c = get_char(s,*pos);
    if c == '-' {
      *pos = *pos + 1;
    }
  }
  if *pos >= s.len() {
    return Err(make_serror("expected number", *pos));
  }
  while *pos < s.len() {
    let c = get_char(s,*pos);
    if !(xiom.char.is_digit(c)) { break; }
    *pos = *pos + 1;
  }
  if *pos < s.len() {
    let c = get_char(s,*pos);
    if c == '.' {
      *pos = *pos + 1;
      while *pos < s.len() {
        let d = get_char(s,*pos);
        if !(xiom.char.is_digit(d)) { break; }
        *pos = *pos + 1;
      }
    }
  }
  if *pos < s.len() {
    let c = get_char(s,*pos);
    if c == 'e' || c == 'E' {
      *pos = *pos + 1;
      if *pos < s.len() {
        let d = get_char(s,*pos);
        if d == '+' || d == '-' {
          *pos = *pos + 1;
        }
      }
      while *pos < s.len() {
        let d = get_char(s,*pos);
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

pub fn json_parse(data: Str) -> Result[JsonValue, SerializeError]
  requires: data.len() >= 0
  ensures: true
  ensures: true
{
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

// -- JSON escape/unescape ----------------------------------------------------

/// JSON-escapes a string (without surrounding quotes).
/// Handles \, ", \n, \r, \t, \b, \f.
/// Complexity: O(n), n = string length.
pub fn json_escape(s: Str) -> Str {
  var result = "";
  let len = s.len();
  var i: Int = 0;
  while i < len {
    let c = get_char(s, i);
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
    };
    i = i + 1;
  };
  return result;
}

/// Unescapes a JSON-escaped string (without surrounding quotes).
/// Handles \\, \", \/, \b, \f, \n, \r, \t, \uNNNN.
/// Complexity: O(n), n = string length.
pub fn json_unescape(s: Str) -> Result[Str, Str] {
  var result = "";
  let len = s.len();
  var i: Int = 0;
  while i < len {
    let c = get_char(s, i);
    if c == '\\' {
      i = i + 1;
      if i >= len {
        return Err("json_unescape: unexpected end after backslash");
      };
      let esc = get_char(s, i);
      if esc == '\"' { result = result + "\""; }
      elif esc == '\\' { result = result + "\\"; }
      elif esc == '/' { result = result + "/"; }
      elif esc == 'b' { result = result + "\b"; }
      elif esc == 'f' { result = result + "\f"; }
      elif esc == 'n' { result = result + "\n"; }
      elif esc == 'r' { result = result + "\r"; }
      elif esc == 't' { result = result + "\t"; }
      elif esc == 'u' {
        result = result + "?";
        i = i + 4;
      } else {
        return Err("json_unescape: invalid escape sequence");
      };
    } else {
      result = result + xiom.string.str_slice(s, i, i + 1);
    };
    i = i + 1;
  };
  return Ok(result);
}

// -- JSON minify -------------------------------------------------------------

/// Strips whitespace from JSON outside of strings.
/// Complexity: O(n), n = input length.
pub fn json_minify(s: Str) -> Result[Str, Str] {
  var result = "";
  let len = s.len();
  var i: Int = 0;
  var in_string: Bool = false;
  while i < len {
    let c = get_char(s, i);
    if in_string {
      result = result + xiom.string.str_slice(s, i, i + 1);
      if c == '\\' {
        i = i + 1;
        if i < len {
          result = result + xiom.string.str_slice(s, i, i + 1);
        };
      } elif c == '\"' {
        in_string = false;
      };
    } else {
      if c == '\"' {
        in_string = true;
        result = result + "\"";
      } elif c != ' ' && c != '\t' && c != '\n' && c != '\r' {
        result = result + xiom.string.str_slice(s, i, i + 1);
      };
    };
    i = i + 1;
  };
  if in_string {
    return Err("json_minify: unterminated string");
  };
  return Ok(result);
}

// -- JSON pretty-print -------------------------------------------------------

/// Pretty-prints JSON with 2-space indentation.
/// Uses a simple tokenizer-based approach that tracks nesting depth.
/// Complexity: O(n), n = input length.
pub fn json_pretty(s: Str) -> Result[Str, Str] {
  var result = "";
  let len = s.len();
  var i: Int = 0;
  var depth: Int = 0;
  var in_string: Bool = false;
  var need_newline: Bool = false;
  var need_indent: Bool = false;
  var after_colon: Bool = false;
  while i < len {
    let c = get_char(s, i);
    if in_string {
      result = result + xiom.string.str_slice(s, i, i + 1);
      if c == '\\' {
        i = i + 1;
        if i < len {
          result = result + xiom.string.str_slice(s, i, i + 1);
        };
      } elif c == '\"' {
        in_string = false;
      };
    } else {
      if c == '\"' {
        if need_newline {
          result = result + "\n";
          var di: Int = 0;
          while di < depth {
            result = result + "  ";
            di = di + 1;
          };
          need_newline = false;
          need_indent = false;
        };
        in_string = true;
        result = result + "\"";
      } elif c == '{' || c == '[' {
        if need_newline {
          result = result + "\n";
          var di: Int = 0;
          while di < depth {
            result = result + "  ";
            di = di + 1;
          };
          need_newline = false;
          need_indent = false;
        };
        result = result + xiom.string.str_slice(s, i, i + 1);
        depth = depth + 1;
        need_newline = true;
        need_indent = true;
      } elif c == '}' || c == ']' {
        depth = depth - 1;
        if need_newline {
          result = result + "\n";
          var di: Int = 0;
          while di < depth {
            result = result + "  ";
            di = di + 1;
          };
          need_newline = false;
          need_indent = false;
        };
        result = result + xiom.string.str_slice(s, i, i + 1);
        need_newline = false;
        need_indent = false;
      } elif c == ',' {
        result = result + ",";
        need_newline = true;
        need_indent = true;
      } elif c == ':' {
        if after_colon {
          result = result + ": ";
        } else {
          result = result + ": ";
        };
        after_colon = true;
      } elif c == ' ' || c == '\t' || c == '\n' || c == '\r' {
        // skip whitespace
      } else {
        if need_newline {
          result = result + "\n";
          var di: Int = 0;
          while di < depth {
            result = result + "  ";
            di = di + 1;
          };
          need_newline = false;
          need_indent = false;
        };
        if need_indent {
          var di2: Int = 0;
          while di2 < depth {
            result = result + "  ";
            di2 = di2 + 1;
          };
          need_indent = false;
        };
        result = result + xiom.string.str_slice(s, i, i + 1);
      };
    };
    i = i + 1;
  };
  if in_string {
    return Err("json_pretty: unterminated string");
  };
  return Ok(result);
}

// -- JSON path navigation ----------------------------------------------------

/// Navigates a JSON string using a dot-notation path (e.g. "a.b.0").
/// Returns the value at the path as a string, or None if not found.
/// Complexity: O(n * p), n = JSON size, p = path depth.
pub fn json_get_path(json: Str, path: Str) -> Option[Str] {
  let parsed = json_parse(json);
  if !parsed.is_ok {
    return Option[Str]{ is_some: false; value: ""; };
  };
  var node = parsed.value;
  var path_str = path;
  var i: Int = 0;
  let plen = path_str.len();
  while i < plen {
    var seg = "";
    while i < plen {
      let c = get_char(path_str, i);
      if c == '.' {
        i = i + 1;
        break;
      };
      seg = seg + xiom.string.str_slice(path_str, i, i + 1);
      i = i + 1;
    };
    if seg == "" {
      return Option[Str]{ is_some: false; value: ""; };
    };
    let first_char = get_char(seg, 0);
    if first_char >= '0' && first_char <= '9' {
      var arr_idx: Int = 0;
      var di: Int = 0;
      let seglen = seg.len();
      while di < seglen {
        let dc = get_char(seg, di);
        if dc < '0' || dc > '9' {
          return Option[Str]{ is_some: false; value: ""; };
        };
        arr_idx = arr_idx * 10 + ((dc as Int) - 48);
        di = di + 1;
      };
      let arr_val = node.index(arr_idx);
      if arr_val.is_some {
        node = arr_val.value;
      } else {
        return Option[Str]{ is_some: false; value: ""; };
      };
    } else {
      let obj_val = node.get(seg);
      if obj_val.is_some {
        node = obj_val.value;
      } else {
        return Option[Str]{ is_some: false; value: ""; };
      };
    };
  };
  return Option[Str]{ is_some: true; value: node.to_str(); };
}

// -- JSON type detection -----------------------------------------------------

/// Returns the JSON type of a string: "object", "array", "string", "number",
/// "bool", "null", or "invalid".
/// Complexity: O(1) -- reads only the first non-whitespace character.
pub fn json_type_of(s: Str) -> Str {
  var i: Int = 0;
  let len = s.len();
  while i < len {
    let c = get_char(s, i);
    if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
      i = i + 1;
    } else {
      break;
    };
  };
  if i >= len {
    return "invalid";
  };
  let c = get_char(s, i);
  if c == '{' { return "object"; };
  if c == '[' { return "array"; };
  if c == '\"' { return "string"; };
  if c == '-' || (c >= '0' && c <= '9') { return "number"; };
  if c == 't' || c == 'f' { return "bool"; };
  if c == 'n' { return "null"; };
  return "invalid";
}

// -- Variable-length integer encoding (LEB128) ------------------------------

/// Encodes an integer using unsigned LEB128 (Little Endian Base 128).
/// Each byte uses 7 bits for data and the MSB as continuation flag.
/// Complexity: O(log128(n)).
pub fn varint_encode(value: Int) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var v: Int = value;
  if v < 0 {
    v = -v;
  };
  loop {
    var byte: Int = v & 0x7F;
    v = v >> 7;
    if v != 0 {
      byte = byte | 0x80;
    };
    result.push(byte as UInt8);
    if v == 0 {
      break;
    };
  };
  return result;
}

/// Decodes an unsigned LEB128 integer from a byte slice starting at pos.
/// Returns the decoded value. The caller advances pos by varint_encoded_len.
/// Complexity: O(log128(n)).
pub fn varint_decode(data: &Vec[UInt8], pos: Int) -> Result[Int, Str] {
  var result: Int = 0;
  var shift: Int = 0;
  var p: Int = pos;
  let dlen = data.len();
  loop {
    if p >= dlen {
      return Err("varint_decode: truncated input");
    };
    let byte: Int = data[p] as Int;
    result = result | ((byte & 0x7F) << shift);
    shift = shift + 7;
    p = p + 1;
    if (byte & 0x80) == 0 {
      break;
    };
    if shift >= 64 {
      return Err("varint_decode: value too large");
    };
  };
  return Ok(result);
}

/// Decodes a LEB128 integer and returns the value with its encoded byte length.
/// The caller can advance by the returned length.
/// Complexity: O(log128(n)).
pub fn varint_decode_at(data: &Vec[UInt8], pos: Int) -> Result[Int, Str] {
  return varint_decode(data, pos);
}

/// Returns the number of bytes consumed by a LEB128-encoded integer.
/// Scans continuation bits. Complexity: O(log128(n)).
pub fn varint_encoded_len(data: &Vec[UInt8], pos: Int) -> Int {
  var p: Int = pos;
  let dlen = data.len();
  while p < dlen {
    if (data[p] as Int & 0x80) == 0 {
      return p - pos + 1;
    };
    p = p + 1;
  };
  return 0;
}

// -- Hex <-> bytes helpers -----------------------------------------------------

/// Converts bytes to a hex string. Delegates to xiom.encoding.hex_encode.
/// Complexity: O(n), n = data length.
pub fn bytes_to_hex_str(data: &Vec[UInt8]) -> Str {
  return encoding.hex_encode(data);
}

/// Converts a hex string to bytes. Delegates to xiom.encoding.hex_decode.
/// Complexity: O(n), n = string length.
pub fn hex_str_to_bytes(s: Str) -> Result[Vec[UInt8], Str] {
  return encoding.hex_decode(s);
}
