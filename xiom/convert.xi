// XIOM — Type Conversion Traits
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert

pub interface From[T] { fn from(value: T) -> Self; }
pub interface Into[T] { fn into(self) -> T; }
pub interface TryFrom[T] { fn try_from(value: T) -> Result<Self, Str>; }
pub interface TryInto[T] { fn try_into(self) -> Result<T, Str>; }

// 8B/M9: Parse a value from a string
pub interface FromStr {
  fn from_str(s: Str) -> Result<Self, Str>
    requires: s.len() > 0
    ensures: true
  ;
}

// Identity conversion
pub fn identity[T](x: T) -> T
  ensures: result == x
{ x }

// Common conversions
pub fn int_to_float(n: Int) -> Float64 {
  return to_float(n);
}

pub fn float_to_int(f: Float64) -> Int {
  return to_int(f);
}

pub fn int_to_string(n: Int) -> Str {
  return to_string(n);
}

pub fn float_to_string(f: Float64) -> Str
  ensures: result.len() > 0
{
  var negative = false;
  var value = f;
  if f < 0.0 {
    negative = true;
    value = -f;
  };
  let int_part = to_int(value);
  let frac = value - to_float(int_part);
  var result = to_string(int_part);
  if frac > 0.0 {
    result = str_concat(result, ".");
    var remaining = frac;
    var count = 0;
    while count < 9 {
      remaining = remaining * 10.0;
      let digit = to_int(remaining);
      result = str_concat(result, to_string(digit));
      remaining = remaining - to_float(digit);
      count = count + 1;
    };
  };
  if negative { return str_concat("-", result); };
  return result;
}

pub fn bool_to_string(b: Bool) -> Str {
  if b { return "true"; };
  return "false";
}

pub fn char_to_int(c: Char) -> Int {
  return to_int_from_char(c);
}

pub fn int_to_char(n: Int) -> Option[Char]
  ensures: true
{
  if n < 0 || n > 1114111 {
    return Option[Char]{ is_some: false, value: '\0' };
  };
  return Option[Char]{ is_some: true, value: to_char(n) };
}
