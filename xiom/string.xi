// XIOM — String Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

fn str_len(s: Str) -> Int {
  s.len()
}

fn str_concat(a: Str, b: Str) -> Str
  ensures: result.len() == a.len() + b.len()
{
  let len_a = a.len();
  let len_b = b.len();
  let total = len_a + len_b;
  unsafe {
    var buf = malloc(total + 1);
    var i: Int = 0;
    while i < len_a {
      buf[i] = xiom_char_at(a, i) as UInt8;
      i = i + 1;
    }
    var j: Int = 0;
    while j < len_b {
      buf[len_a + j] = xiom_char_at(b, j) as UInt8;
      j = j + 1;
    }
    buf[total] = 0;
    return Str.from_cstring(buf);
  }
}

fn str_slice(s: Str, start: Int, end: Int) -> Str
  requires: start >= 0
  requires: end >= start
  requires: end <= s.len()
{
  let len = s.len();
  var s_start = start;
  var s_end = end;
  if s_start < 0 { s_start = 0; };
  if s_end > len { s_end = len; };
  if s_start >= s_end { return ""; };
  let slice_len = s_end - s_start;
  unsafe {
    var buf = malloc(slice_len + 1);
    var i: Int = 0;
    while i < slice_len {
      buf[i] = xiom_char_at(s, s_start + i) as UInt8;
      i = i + 1;
    }
    buf[slice_len] = 0;
    return Str.from_cstring(buf);
  }
}

fn str_contains(s: Str, substr: Str) -> Bool {
  let result = index_of(s, substr);
  result.is_some
}

fn str_starts_with(s: Str, prefix: Str) -> Bool {
  let prefix_len = prefix.len();
  if prefix_len > s.len() {
    return false;
  };
  str_slice(s, 0, prefix_len) == prefix
}

fn str_ends_with(s: Str, suffix: Str) -> Bool {
  let suffix_len = suffix.len();
  let s_len = s.len();
  if suffix_len > s_len {
    return false;
  };
  str_slice(s, s_len - suffix_len, s_len) == suffix
}

fn str_split(s: Str, delimiter: Str) -> Vec[Str]
  requires: delimiter.len() > 0
  ensures:  result.len() >= 1  // always at least one element
{
  var result = Vec[Str].new();
  let delim_len = delimiter.len();
  let s_len = s.len();
  if delim_len == 0 {
    var i: Int = 0;
    while i < s_len {
      result.push(str_slice(s, i, i + 1));
      i = i + 1;
    }
    return result;
  };
  var start: Int = 0;
  var pos: Int = 0;
  while pos < s_len {
    if pos + delim_len <= s_len && str_slice(s, pos, pos + delim_len) == delimiter {
      result.push(str_slice(s, start, pos));
      pos = pos + delim_len;
      start = pos;
    } else {
      pos = pos + 1;
    };
  }
  result.push(str_slice(s, start, s_len));
  result
}

fn str_trim(s: Str) -> Str
  ensures: result.len() <= s.len()  // trim never increases length
{
  let len = s.len();
  var start: Int = 0;
  var end: Int = len;
  while start < len && xiom.char.is_whitespace(xiom_char_at(s, start)) {
    start = start + 1;
  }
  while end > start && xiom.char.is_whitespace(xiom_char_at(s, end - 1)) {
    end = end - 1;
  }
  str_slice(s, start, end)
}

fn str_to_int(s: Str) -> Result[Int, Str]
  requires: s.len() > 0
{
  xiom.core.to_int_from_str(s)
}

fn str_to_float(s: Str) -> Result[Float64, Str]
  requires: s.len() > 0
{
  xiom.core.to_float_from_str(s)
}

fn str_upper(s: Str) -> Str
  ensures: result.len() == s.len()
{
  let len = s.len();
  unsafe {
    var buf = malloc(len + 1);
    var i: Int = 0;
    while i < len {
      let c = xiom_char_at(s, i);
      buf[i] = xiom.char.to_uppercase(c) as UInt8;
      i = i + 1;
    }
    buf[len] = 0;
    return Str.from_cstring(buf);
  }
}

fn str_lower(s: Str) -> Str
  ensures: result.len() == s.len()
{
  let len = s.len();
  unsafe {
    var buf = malloc(len + 1);
    var i: Int = 0;
    while i < len {
      let c = xiom_char_at(s, i);
      buf[i] = xiom.char.to_lowercase(c) as UInt8;
      i = i + 1;
    }
    buf[len] = 0;
    return Str.from_cstring(buf);
  }
}

fn format(fmt: Str) -> Str {
  fmt
}

fn format1(fmt: Str, arg: Str) -> Str
  ensures: result.len() >= fmt.len() - 2 + arg.len()
{
  let idx_opt = index_of(fmt, "{}");
  match idx_opt {
    Some(idx) => {
      let before = str_slice(fmt, 0, idx);
      let after = str_slice(fmt, idx + 2, str_len(fmt));
      str_concat(str_concat(before, arg), after)
    };
    None => fmt;
  }
}

fn format2(fmt: Str, arg1: Str, arg2: Str) -> Str {
  let s = format1(fmt, arg1);
  format1(s, arg2)
}

fn char_at(s: Str, pos: Int) -> Option[Char]
  ensures: result is Some => pos >= 0 && pos < s.char_count()
  ensures: result is None => pos < 0 || pos >= s.char_count()
{
  if pos < 0 || pos >= s.len() {
    return None;
  };
  Some(xiom_char_at(s, pos))
}

fn index_of(s: Str, substr: Str) -> Option[Int]
  requires: substr.len() > 0
  ensures:  result is Some => result >= 0 && result < s.len()
{
  let s_len = s.len();
  let sub_len = substr.len();
  if sub_len > s_len {
    return None;
  };
  if sub_len == 0 {
    return Some(0);
  };
  var i: Int = 0;
  while i <= s_len - sub_len {
    if str_slice(s, i, i + sub_len) == substr {
      return Some(i);
    };
    i = i + 1;
  };
  None
}

fn last_index_of(s: Str, substr: Str) -> Option[Int] {
  let s_len = s.len();
  let sub_len = substr.len();
  if sub_len > s_len {
    return None;
  };
  if sub_len == 0 {
    return Some(s_len);
  };
  var i: Int = s_len - sub_len;
  while i >= 0 {
    if str_slice(s, i, i + sub_len) == substr {
      return Some(i);
    };
    i = i - 1;
  };
  None
}

fn replace(s: Str, from: Str, to: Str) -> Str
  requires: from.len() > 0
{
  let from_len = from.len();
  if from_len == 0 {
    return s;
  };
  var result = "";
  var pos: Int = 0;
  let s_len = s.len();
  loop {
    if pos >= s_len {
      break;
    };
    let rem = str_slice(s, pos, s_len);
    let idx_opt = index_of(rem, from);
    match idx_opt {
      Some(idx) => {
        result = str_concat(result, str_slice(s, pos, pos + idx));
        result = str_concat(result, to);
        pos = pos + idx + from_len;
      };
      None => {
        result = str_concat(result, str_slice(s, pos, s_len));
        break;
      };
    };
  }
  result
}

fn lines(s: Str) -> Vec[Str] {
  str_split(s, "\n")
}

fn words(s: Str) -> Vec[Str] {
  var result = Vec[Str].new();
  let len = s.len();
  var i: Int = 0;
  while i < len {
    while i < len && xiom.char.is_whitespace(xiom_char_at(s, i)) {
      i = i + 1;
    }
    if i < len {
      var start = i;
      while i < len && !xiom.char.is_whitespace(xiom_char_at(s, i)) {
        i = i + 1;
      }
      result.push(str_slice(s, start, i));
    };
  }
  result
}

fn is_empty(s: Str) -> Bool {
  s.len() == 0
}

fn char_count(s: Str) -> Int {
  var count: Int = 0;
  let len = s.len();
  var i: Int = 0;
  while i < len {
    let c = xiom_char_at(s, i);
    let byte_len = xiom.char.len_utf8(c);
    i = i + byte_len;
    count = count + 1;
  }
  count
}

fn byte_count(s: Str) -> Int {
  s.len()
}
