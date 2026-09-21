// XIOM -- Serialize: TOML (v1 subset)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.serialize.toml

use xiom.string;
use xiom.convert;

/// TOML v1 reader (the subset a package manifest needs).
/// 
/// Supported: comments; bare and quoted keys; `[table]` and `[a.b]` headers;
/// basic strings with the five common escapes; literal strings; integers
/// (decimal, optional sign, `_` separators); floats; booleans; arrays of
/// strings/ints/floats. Keys are stored section-qualified with '.'
/// ("package.name"), in file order.
/// 
/// NOT in v1: dates/times, multi-line strings, inline tables,
/// arrays-of-tables, dotted keys in assignment position. The WRITER
/// (`toml_write`) emits the same subset: flat section-qualified keys, root
/// keys first, `[section]` blocks in first-appearance order, the five
/// common escapes. Errors carry the 1-based line number.
pub type TomlValue = enum {
  TStr(Str),
  TInt(Int),
  TFloat(Float64),
  TBool(Bool),
  TStrArray(Vec[Str]),
  TIntArray(Vec[Int]),
  TFloatArray(Vec[Float64]),
}

/// Parsed TOML table (ordered key -> value map).
pub type TomlTable = {
  keys: Vec[Str];
  values: Vec[TomlValue];
}

// ---------------------------------------------------------------- helpers

fn _strip_cr(line: Str) -> Str {
  let len = string.str_len(line);
  if len > 0 && string.byte_at(line, len - 1) == 13 {
    return string.str_slice(line, 0, len - 1);
  }
  return line;
}

// Index of the first '#' that is not inside a quoted region, or -1.
fn _comment_index(line: Str) -> Int {
  var i = 0;
  var in_basic = false;
  var in_literal = false;
  let len = string.str_len(line);
  while i < len {
    let b = string.byte_at(line, i);
    if in_basic {
      if b == 92 {
        i = i + 2;
        continue;
      }
      if b == 34 { in_basic = false; }
    } elif in_literal {
      if b == 39 { in_literal = false; }
    } else {
      if b == 34 { in_basic = true; }
      elif b == 39 { in_literal = true; }
      elif b == 35 { return i; }
    }
    i = i + 1;
  }
  return 0 - 1;
}

fn _clean_line(line: Str) -> Str {
  let cr = _strip_cr(line);
  let ci = _comment_index(cr);
  if ci >= 0 {
    return string.str_trim(string.str_slice(cr, 0, ci));
  }
  return string.str_trim(cr);
}

// First '=' at top level (outside quotes), or -1.
fn _equals_index(line: Str) -> Int {
  var i = 0;
  var in_basic = false;
  var in_literal = false;
  let len = string.str_len(line);
  while i < len {
    let b = string.byte_at(line, i);
    if in_basic {
      if b == 92 { i = i + 2; continue; }
      if b == 34 { in_basic = false; }
    } elif in_literal {
      if b == 39 { in_literal = false; }
    } else {
      if b == 34 { in_basic = true; }
      elif b == 39 { in_literal = true; }
      elif b == 61 { return i; }
    }
    i = i + 1;
  }
  return 0 - 1;
}

fn _is_bare_key_char(b: UInt8) -> Bool {
  if b >= 65 && b <= 90 { return true; }
  if b >= 97 && b <= 122 { return true; }
  if b >= 48 && b <= 57 { return true; }
  return b == 95 || b == 45;
}

fn _parse_key(s: Str) -> Result[Str, Str] {
  let len = string.str_len(s);
  if len == 0 {
    return Err("toml: empty key");
  }
  let first = string.byte_at(s, 0);
  if first == 34 {
    if len < 2 || string.byte_at(s, len - 1) != 34 {
      return Err("toml: unterminated quoted key");
    }
    return Ok(_unescape_basic(string.str_slice(s, 1, len - 1)));
  }
  if first == 39 {
    if len < 2 || string.byte_at(s, len - 1) != 39 {
      return Err("toml: unterminated literal key");
    }
    return Ok(string.str_slice(s, 1, len - 1));
  }
  var i = 0;
  while i < len {
    if !_is_bare_key_char(string.byte_at(s, i)) {
      return Err("toml: invalid bare key character at " + convert.int_to_string(i));
    }
    i = i + 1;
  }
  return Ok(s);
}

fn _unescape_basic(s: Str) -> Str {
  var out = "";
  var i = 0;
  let len = string.str_len(s);
  while i < len {
    let b = string.byte_at(s, i);
    if b == 92 && i + 1 < len {
      let n = string.byte_at(s, i + 1);
      if n == 110 { out = out + "\n"; i = i + 2; continue; }
      if n == 116 { out = out + "\t"; i = i + 2; continue; }
      if n == 114 { out = out + "\r"; i = i + 2; continue; }
      if n == 34 { out = out + "\""; i = i + 2; continue; }
      if n == 92 { out = out + "\\"; i = i + 2; continue; }
    }
    out = out + string.str_slice(s, i, i + 1);
    i = i + 1;
  }
  return out;
}

fn _parse_basic_string(v: Str) -> Result[Str, Str] {
  let len = string.str_len(v);
  if len < 2 || string.byte_at(v, len - 1) != 34 {
    return Err("toml: unterminated basic string");
  }
  return Ok(_unescape_basic(string.str_slice(v, 1, len - 1)));
}

fn _parse_literal_string(v: Str) -> Result[Str, Str] {
  let len = string.str_len(v);
  if len < 2 || string.byte_at(v, len - 1) != 39 {
    return Err("toml: unterminated literal string");
  }
  return Ok(string.str_slice(v, 1, len - 1));
}

// Split the inside of an array on top-level commas; strings may contain
// commas. Returns trimmed element slices.
fn _split_array_items(inner: Str) -> Vec[Str] {
  var out = Vec[Str].new();
  var start = 0;
  var i = 0;
  var in_basic = false;
  var in_literal = false;
  let len = string.str_len(inner);
  while i < len {
    let b = string.byte_at(inner, i);
    if in_basic {
      if b == 92 { i = i + 2; continue; }
      if b == 34 { in_basic = false; }
    } elif in_literal {
      if b == 39 { in_literal = false; }
    } else {
      if b == 34 { in_basic = true; }
      elif b == 39 { in_literal = true; }
      elif b == 44 {
        out.push(string.str_trim(string.str_slice(inner, start, i)));
        start = i + 1;
      }
    }
    i = i + 1;
  }
  let tail = string.str_trim(string.str_slice(inner, start, len));
  if string.str_len(tail) > 0 {
    out.push(tail);
  }
  return out;
}

fn _remove_underscores(s: Str) -> Str {
  var out = "";
  var i = 0;
  let len = string.str_len(s);
  while i < len {
    if string.byte_at(s, i) != 95 {
      out = out + string.str_slice(s, i, i + 1);
    }
    i = i + 1;
  }
  return out;
}

fn _looks_float(s: Str) -> Bool {
  var i = 0;
  let len = string.str_len(s);
  while i < len {
    let b = string.byte_at(s, i);
    if b == 46 || b == 101 || b == 69 { return true; }
    i = i + 1;
  }
  return false;
}

// Classify array elements into a typed array value.
fn _parse_array(inner: Str) -> Result[TomlValue, Str] {
  let items = _split_array_items(inner);
  let n = items.len();
  if n == 0 {
    var empty = Vec[Str].new();
    return Ok(TomlValue.TStrArray(empty));
  }
  var kind = 0;  // 1 string, 2 int, 3 float
  var i = 0;
  var str_vals = Vec[Str].new();
  var int_vals = Vec[Int].new();
  var float_vals = Vec[Float64].new();
  while i < n {
    let it = items[i];
    let first = string.byte_at(it, 0);
    if first == 34 {
      let r = _parse_basic_string(it);
      match r { Ok(v) => { str_vals.push(v); }, Err(e) => { return Err(e); } }
      if kind == 0 { kind = 1; } elif kind != 1 { return Err("toml: mixed array types"); }
    } elif first == 39 {
      let r = _parse_literal_string(it);
      match r { Ok(v) => { str_vals.push(v); }, Err(e) => { return Err(e); } }
      if kind == 0 { kind = 1; } elif kind != 1 { return Err("toml: mixed array types"); }
    } else {
      let cleaned = _remove_underscores(it);
      if _looks_float(cleaned) {
        let r = string.str_to_float(cleaned);
        match r { Ok(v) => { float_vals.push(v); }, Err(e) => { return Err(e); } }
        if kind == 0 { kind = 3; } elif kind != 3 { return Err("toml: mixed array types"); }
      } else {
        let r = string.str_to_int(cleaned);
        match r { Ok(v) => { int_vals.push(v); }, Err(e) => { return Err(e); } }
        if kind == 0 { kind = 2; } elif kind != 2 { return Err("toml: mixed array types"); }
      }
    }
    i = i + 1;
  }
  if kind == 1 { return Ok(TomlValue.TStrArray(str_vals)); }
  if kind == 2 { return Ok(TomlValue.TIntArray(int_vals)); }
  return Ok(TomlValue.TFloatArray(float_vals));
}

fn _parse_scalar(v: Str) -> Result[TomlValue, Str] {
  let len = string.str_len(v);
  if len == 0 {
    return Err("toml: missing value");
  }
  let first = string.byte_at(v, 0);
  if first == 34 {
    let r = _parse_basic_string(v);
    match r { Ok(s) => { return Ok(TomlValue.TStr(s)); }, Err(e) => { return Err(e); } }
  }
  if first == 39 {
    let r = _parse_literal_string(v);
    match r { Ok(s) => { return Ok(TomlValue.TStr(s)); }, Err(e) => { return Err(e); } }
  }
  if v == "true" { return Ok(TomlValue.TBool(true)); }
  if v == "false" { return Ok(TomlValue.TBool(false)); }
  if first == 91 {
    if string.byte_at(v, len - 1) != 93 {
      return Err("toml: unterminated array");
    }
    return _parse_array(string.str_slice(v, 1, len - 1));
  }
  let cleaned = _remove_underscores(v);
  if _looks_float(cleaned) {
    let r = string.str_to_float(cleaned);
    match r { Ok(f) => { return Ok(TomlValue.TFloat(f)); }, Err(e) => { return Err(e); } }
  }
  let ri = string.str_to_int(cleaned);
  match ri { Ok(n) => { return Ok(TomlValue.TInt(n)); }, Err(e) => { return Err(e); } }
}

fn _table_find(t: &TomlTable, key: Str) -> Int {
  var i = 0;
  while i < t.keys.len() {
    if t.keys[i] == key {
      return i;
    }
    i = i + 1;
  }
  return 0 - 1;
}

// ------------------------------------------------------------------- API

/// Parse a TOML v1 subset document; keys are section-qualified ("a.b").
/// Errors carry the 1-based source line.
pub fn toml_parse(text: Str) -> Result[TomlTable, Str] {
  var t = TomlTable{ keys: Vec[Str].new(); values: Vec[TomlValue].new(); };
  let raw_lines = string.str_split(text, "\n");
  var prefix = "";
  var ln = 0;
  while ln < raw_lines.len() {
    let line_no = ln + 1;
    let line = _clean_line(raw_lines[ln]);
    ln = ln + 1;
    if string.str_len(line) == 0 {
      continue;
    }
    if string.byte_at(line, 0) == 91 {
      let llen = string.str_len(line);
      if llen < 2 || string.byte_at(line, llen - 1) != 93 {
        return Err("toml: malformed table header at line " + convert.int_to_string(line_no));
      }
      let name = string.str_trim(string.str_slice(line, 1, llen - 1));
      if string.str_len(name) == 0 {
        return Err("toml: empty table name at line " + convert.int_to_string(line_no));
      }
      prefix = name;
      continue;
    }
    let eq = _equals_index(line);
    if eq < 0 {
      return Err("toml: expected key = value at line " + convert.int_to_string(line_no));
    }
    let key_part = string.str_trim(string.str_slice(line, 0, eq));
    let val_part = string.str_trim(string.str_slice(line, eq + 1, string.str_len(line)));
    let kr = _parse_key(key_part);
    var key = "";
    match kr { Ok(k) => { key = k; }, Err(e) => { return Err(e); } }
    if string.str_len(prefix) > 0 {
      key = prefix + "." + key;
    }
    let vr = _parse_scalar(val_part);
    var value = TomlValue.TBool(false);
    match vr { Ok(v) => { value = v; }, Err(e) => { return Err(e); } }
    if _table_find(&t, key) >= 0 {
      return Err("toml: duplicate key '" + key + "' at line " + convert.int_to_string(line_no));
    }
    t.keys.push(key);
    t.values.push(value);
  }
  return Ok(t);
}

/// Value for `key`, or None when missing.
pub fn toml_get(t: &TomlTable, key: Str) -> Option[TomlValue] {
  let idx = _table_find(t, key);
  if idx < 0 {
    return None;
  }
  return Some(t.values[idx]);
}

/// True when `key` exists.
pub fn toml_has(t: &TomlTable, key: Str) -> Bool {
  return _table_find(t, key) >= 0;
}

/// String value for `key`, or None when missing or of another type.
pub fn toml_get_str(t: &TomlTable, key: Str) -> Option[Str] {
  match toml_get(t, key) {
    Some(v) => {
      match v {
        TomlValue.TStr(s) => { return Some(s); },
        _ => { return None; },
      }
    },
    None => { return None; },
  }
}

/// Int value for `key`, or None when missing or of another type.
pub fn toml_get_int(t: &TomlTable, key: Str) -> Option[Int] {
  match toml_get(t, key) {
    Some(v) => {
      match v {
        TomlValue.TInt(n) => { return Some(n); },
        _ => { return None; },
      }
    },
    None => { return None; },
  }
}

/// Float value for `key`, or None when missing or of another type.
pub fn toml_get_float(t: &TomlTable, key: Str) -> Option[Float64] {
  match toml_get(t, key) {
    Some(v) => {
      match v {
        TomlValue.TFloat(f) => { return Some(f); },
        _ => { return None; },
      }
    },
    None => { return None; },
  }
}

/// Bool value for `key`, or None when missing or of another type.
pub fn toml_get_bool(t: &TomlTable, key: Str) -> Option[Bool] {
  match toml_get(t, key) {
    Some(v) => {
      match v {
        TomlValue.TBool(b) => { return Some(b); },
        _ => { return None; },
      }
    },
    None => { return None; },
  }
}

/// String-array value for `key`, or None when missing or of another type.
pub fn toml_get_str_array(t: &TomlTable, key: Str) -> Option[Vec[Str]] {
  match toml_get(t, key) {
    Some(v) => {
      match v {
        TomlValue.TStrArray(a) => { return Some(a); },
        _ => { return None; },
      }
    },
    None => { return None; },
  }
}

/// Int-array value for `key`, or None when missing or of another type.
pub fn toml_get_int_array(t: &TomlTable, key: Str) -> Option[Vec[Int]] {
  match toml_get(t, key) {
    Some(v) => {
      match v {
        TomlValue.TIntArray(a) => { return Some(a); },
        _ => { return None; },
      }
    },
    None => { return None; },
  }
}

/// All keys in file order.
pub fn toml_keys(t: &TomlTable) -> Vec[Str] {
  return t.keys;
}

// ============================================================================
// TOML writer (emitter) -- mirrors the reader subset exactly.
// ============================================================================

fn _toml_escape(s: Str) -> Str {
  var out = "";
  let len = string.str_len(s);
  var i = 0;
  while i < len {
    let b = string.byte_at(s, i);
    if b == 92 {
      out = out + "\\\\";
    } elif b == 34 {
      out = out + "\\\"";
    } elif b == 10 {
      out = out + "\\n";
    } elif b == 9 {
      out = out + "\\t";
    } elif b == 13 {
      out = out + "\\r";
    } else {
      out = out + string.str_slice(s, i, i + 1);
    }
    i = i + 1;
  }
  return out;
}

fn _toml_bare_byte(b: Int) -> Bool {
  if b >= 65 && b <= 90 { return true; }
  if b >= 97 && b <= 122 { return true; }
  if b >= 48 && b <= 57 { return true; }
  return b == 95 || b == 45;
}

fn _toml_write_key(k: Str) -> Str {
  let len = string.str_len(k);
  if len == 0 { return "\"\""; }
  var i = 0;
  while i < len {
    if !_toml_bare_byte(string.byte_at(k, i)) {
      return "\"" + _toml_escape(k) + "\"";
    }
    i = i + 1;
  }
  return k;
}

fn _toml_has_float_marker(s: Str) -> Bool {
  var i = 0;
  let len = string.str_len(s);
  while i < len {
    let b = string.byte_at(s, i);
    if b == 46 || b == 101 || b == 69 { return true; }
    i = i + 1;
  }
  return false;
}

fn _toml_write_float(f: Float64) -> Str {
  if f != f { return "nan"; }
  let s = convert.float_to_string(f);
  if s == "inf" || s == "-inf" { return s; }
  if _toml_has_float_marker(s) { return s; }
  return s + ".0";
}

fn _toml_write_value(v: TomlValue) -> Str {
  match v {
    TomlValue.TStr(s) => { return "\"" + _toml_escape(s) + "\""; },
    TomlValue.TInt(n) => { return convert.int_to_string(n); },
    TomlValue.TFloat(f) => { return _toml_write_float(f); },
    TomlValue.TBool(b) => {
      if b { return "true"; }
      return "false";
    },
    TomlValue.TStrArray(items) => {
      var out = "[";
      var i = 0;
      while i < items.len() {
        if i > 0 { out = out + ", "; }
        out = out + "\"" + _toml_escape(items[i]) + "\"";
        i = i + 1;
      }
      return out + "]";
    },
    TomlValue.TIntArray(items) => {
      var out = "[";
      var i = 0;
      while i < items.len() {
        if i > 0 { out = out + ", "; }
        out = out + convert.int_to_string(items[i]);
        i = i + 1;
      }
      return out + "]";
    },
    TomlValue.TFloatArray(items) => {
      var out = "[";
      var i = 0;
      while i < items.len() {
        if i > 0 { out = out + ", "; }
        out = out + _toml_write_float(items[i]);
        i = i + 1;
      }
      return out + "]";
    },
    _ => { return ""; },
  }
}

fn _toml_list_has(items: &Vec[Str], s: Str) -> Bool {
  var i = 0;
  while i < items.len() {
    if items[i] == s { return true; }
    i = i + 1;
  }
  return false;
}

/// Render `t` as TOML text for the v1 subset: root keys first (file order),
/// then one `[section]` block per dotted-key prefix, in first-appearance
/// order. Round-trips through `toml_parse` except for non-finite floats
/// (written as `nan`/`inf`, which the v1 reader does not accept back).
/// Complexity: O(n^2) worst case in the number of keys (section grouping).
pub fn toml_write(t: &TomlTable) -> Str {
  var out = "";
  var i = 0;
  while i < t.keys.len() {
    if !string.str_rindex_of(t.keys[i], ".").is_some {
      out = out + _toml_write_key(t.keys[i]) + " = " + _toml_write_value(t.values[i]) + "\n";
    }
    i = i + 1;
  }
  var sections = Vec[Str].new();
  i = 0;
  while i < t.keys.len() {
    let dot_opt = string.str_rindex_of(t.keys[i], ".");
    if dot_opt.is_some {
      let dot = dot_opt.value;
      let section = string.str_slice(t.keys[i], 0, dot);
      if !_toml_list_has(&sections, section) {
        sections.push(section);
        out = out + "[" + section + "]\n";
        var j = 0;
        while j < t.keys.len() {
          let dot2_opt = string.str_rindex_of(t.keys[j], ".");
          if dot2_opt.is_some {
            let dot2 = dot2_opt.value;
            if string.str_slice(t.keys[j], 0, dot2) == section {
              out = out + _toml_write_key(string.str_slice(t.keys[j], dot2 + 1, string.str_len(t.keys[j]))) + " = " + _toml_write_value(t.values[j]) + "\n";
            }
          }
          j = j + 1;
        }
      }
    }
    i = i + 1;
  }
  return out;
}
