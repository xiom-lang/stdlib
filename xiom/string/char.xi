// XIOM -- Character Operations
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.char

pub fn is_alphabetic(c: Char) -> Bool
  ensures: result == ((to_int_from_char(c) >= 65 && to_int_from_char(c) <= 90) || (to_int_from_char(c) >= 97 && to_int_from_char(c) <= 122))
{
  let code = to_int_from_char(c);
  return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
}

pub fn is_alphanumeric(c: Char) -> Bool
  ensures: result == (is_alphabetic(c) || is_digit(c))
{
  return is_alphabetic(c) || is_digit(c);
}

pub fn is_ascii(c: Char) -> Bool
  ensures: result == (to_int_from_char(c) <= 127)
{
  let code = to_int_from_char(c);
  return code <= 127;
}

pub fn is_control(c: Char) -> Bool
  ensures: result == ((to_int_from_char(c) >= 0 && to_int_from_char(c) <= 31) || to_int_from_char(c) == 127)
{
  let code = to_int_from_char(c);
  return (code >= 0 && code <= 31) || code == 127;
}

pub fn is_digit(c: Char) -> Bool
  ensures: result == (to_int_from_char(c) >= 48 && to_int_from_char(c) <= 57)
{
  let code = to_int_from_char(c);
  return code >= 48 && code <= 57;
}

pub fn is_lowercase(c: Char) -> Bool
  ensures: result == (to_int_from_char(c) >= 97 && to_int_from_char(c) <= 122)
{
  let code = to_int_from_char(c);
  return code >= 97 && code <= 122;
}

pub fn is_uppercase(c: Char) -> Bool
  ensures: result == (to_int_from_char(c) >= 65 && to_int_from_char(c) <= 90)
{
  let code = to_int_from_char(c);
  return code >= 65 && code <= 90;
}

pub fn is_numeric(c: Char) -> Bool
  ensures: result == is_digit(c)
{
  return is_digit(c);
}

pub fn is_punctuation(c: Char) -> Bool
  ensures: result == ((to_int_from_char(c) >= 33 && to_int_from_char(c) <= 47) || (to_int_from_char(c) >= 58 && to_int_from_char(c) <= 64) || (to_int_from_char(c) >= 91 && to_int_from_char(c) <= 96) || (to_int_from_char(c) >= 123 && to_int_from_char(c) <= 126))
{
  let code = to_int_from_char(c);
  return (code >= 33 && code <= 47)
      || (code >= 58 && code <= 64)
      || (code >= 91 && code <= 96)
      || (code >= 123 && code <= 126);
}

pub fn is_whitespace(c: Char) -> Bool
  ensures: result == (to_int_from_char(c) == 32 || to_int_from_char(c) == 9 || to_int_from_char(c) == 10 || to_int_from_char(c) == 13)
{
  let code = to_int_from_char(c);
  return code == 32 || code == 9 || code == 10 || code == 13;
}

pub fn to_lowercase(c: Char) -> Char {
  let code = to_int_from_char(c);
  if code >= 65 && code <= 90 {
    return to_char(code + 32);
  };
  return c;
}

pub fn to_uppercase(c: Char) -> Char {
  let code = to_int_from_char(c);
  if code >= 97 && code <= 122 {
    return to_char(code - 32);
  };
  return c;
}

pub fn to_digit(c: Char, radix: Int) -> Option[Int]
  ensures: radix < 2 || radix > 36 => result is None
  ensures: result is Some => result.value >= 0
{
  if radix < 2 || radix > 36 {
    return None;
  };
  let code = to_int_from_char(c);
  if code >= 48 && code <= 57 {
    let val = code - 48;
    if val < radix {
      return Some(val);
    };
    return None;
  };
  if code >= 65 && code <= 90 {
    let val = code - 65 + 10;
    if val < radix {
      return Some(val);
    };
    return None;
  };
  if code >= 97 && code <= 122 {
    let val = code - 97 + 10;
    if val < radix {
      return Some(val);
    };
    return None;
  };
  return None;
}

pub fn from_digit(n: Int, radix: Int) -> Option[Char]
  ensures: n < 0 || n >= radix => result is None
  ensures: radix < 2 || radix > 36 => result is None
{
  if radix < 2 || radix > 36 {
    return None;
  };
  if n < 0 || n >= radix {
    return None;
  };
  if n < 10 {
    return Some(to_char(n + 48));
  };
  return Some(to_char(n - 10 + 65));
}

pub fn len_utf8(c: Char) -> Int
  ensures: result >= 1 && result <= 4
{
  let code = to_int_from_char(c);
  if code <= 0x7F {
    return 1;
  };
  if code <= 0x7FF {
    return 2;
  };
  if code <= 0xFFFF {
    return 3;
  };
  return 4;
}

pub fn encode_utf8(c: Char, buf: &mut Vec[UInt8]) {
  let code = to_int_from_char(c);
  if code <= 0x7F {
    buf.push(code);
  } elif code <= 0x7FF {
    buf.push(0xC0 | (code >> 6));
    buf.push(0x80 | (code & 0x3F));
  } elif code <= 0xFFFF {
    buf.push(0xE0 | (code >> 12));
    buf.push(0x80 | ((code >> 6) & 0x3F));
    buf.push(0x80 | (code & 0x3F));
  } else {
    buf.push(0xF0 | (code >> 18));
    buf.push(0x80 | ((code >> 12) & 0x3F));
    buf.push(0x80 | ((code >> 6) & 0x3F));
    buf.push(0x80 | (code & 0x3F));
  };
}

// --------------------------------------------------
//  Extended Character Functions
// --------------------------------------------------

// -- Aliases & Shorthands --

// Alias for is_alphabetic. Returns true if `c` is an ASCII letter (a-z, A-Z).
pub fn is_letter(c: Char) -> Bool
  ensures: result == is_alphabetic(c)
{
  is_alphabetic(c)
}

// Alias for is_control. Returns true if `c` is a C0 control character or DEL.
pub fn is_control_char(c: Char) -> Bool
  ensures: result == is_control(c)
{
  is_control(c)
}

// -- Digit Classification --

// Returns true if `c` is a hexadecimal digit (0-9, a-f, A-F).
pub fn is_hex_digit(c: Char) -> Bool
  ensures: result == ((to_int_from_char(c) >= 48 && to_int_from_char(c) <= 57) || (to_int_from_char(c) >= 65 && to_int_from_char(c) <= 70) || (to_int_from_char(c) >= 97 && to_int_from_char(c) <= 102))
{
  let code = to_int_from_char(c);
  return (code >= 48 && code <= 57) || (code >= 65 && code <= 70) || (code >= 97 && code <= 102);
}

// Returns true if `c` is a binary digit ('0' or '1').
pub fn is_binary_digit(c: Char) -> Bool
  ensures: result == (c == '0' || c == '1')
{
  c == '0' || c == '1'
}

// Returns true if `c` is an octal digit ('0' through '7').
pub fn is_octal_digit(c: Char) -> Bool
  ensures: result == (c >= '0' && c <= '7')
{
  c >= '0' && c <= '7'
}

// -- Unicode Categories --

// Returns true if `c` is a symbol character (punctuation, currency, math, or modifier).
// Covers ASCII punctuation + common Unicode symbol ranges.
pub fn is_symbol(c: Char) -> Bool
  ensures: result == (is_currency(c) || is_math_symbol(c) || is_punctuation(c) || (to_int_from_char(c) >= 0x00A0 && to_int_from_char(c) <= 0x00BF) || (to_int_from_char(c) >= 0x00D7 && to_int_from_char(c) <= 0x00F7) || (to_int_from_char(c) >= 0x2010 && to_int_from_char(c) <= 0x2027) || (to_int_from_char(c) >= 0x2030 && to_int_from_char(c) <= 0x205E) || (to_int_from_char(c) >= 0x2190 && to_int_from_char(c) <= 0x21FF) || (to_int_from_char(c) >= 0x2300 && to_int_from_char(c) <= 0x23FF) || (to_int_from_char(c) >= 0x2500 && to_int_from_char(c) <= 0x257F) || (to_int_from_char(c) >= 0x2580 && to_int_from_char(c) <= 0x259F) || (to_int_from_char(c) >= 0x25A0 && to_int_from_char(c) <= 0x25FF) || (to_int_from_char(c) >= 0x2600 && to_int_from_char(c) <= 0x26FF) || (to_int_from_char(c) >= 0x2700 && to_int_from_char(c) <= 0x27BF))
{
  let code = to_int_from_char(c);
  if is_currency(c) { return true; };
  if is_math_symbol(c) { return true; };
  return is_punctuation(c)
      || (code >= 0x00A0 && code <= 0x00BF)    // Latin-1 supplement symbols
      || (code >= 0x00D7 && code <= 0x00F7)    // x, /
      || (code >= 0x2010 && code <= 0x2027)    // General punctuation
      || (code >= 0x2030 && code <= 0x205E)    // General punctuation continued
      || (code >= 0x2190 && code <= 0x21FF)    // Arrows
      || (code >= 0x2300 && code <= 0x23FF)    // Miscellaneous technical
      || (code >= 0x2500 && code <= 0x257F)    // Box drawing
      || (code >= 0x2580 && code <= 0x259F)    // Block elements
      || (code >= 0x25A0 && code <= 0x25FF)    // Geometric shapes
      || (code >= 0x2600 && code <= 0x26FF)    // Miscellaneous symbols
      || (code >= 0x2700 && code <= 0x27BF);    // Dingbats
}

// Returns true if `c` is a currency symbol.
// Covers $, cent, pound, yen, and the currency symbols block U+20A0..U+20CF.
pub fn is_currency(c: Char) -> Bool
  ensures: result == (to_int_from_char(c) == 0x24 || to_int_from_char(c) == 0xA2 || to_int_from_char(c) == 0xA3 || to_int_from_char(c) == 0xA5 || (to_int_from_char(c) >= 0x20A0 && to_int_from_char(c) <= 0x20CF))
{
  let code = to_int_from_char(c);
  return code == 0x24 || code == 0xA2 || code == 0xA3 || code == 0xA5
      || (code >= 0x20A0 && code <= 0x20CF);
}

// Returns true if `c` is a mathematical symbol.
// Covers +, -, *, /, =, <, >, the plus-minus sign, and the mathematical
// operators block U+2200..U+22FF.
pub fn is_math_symbol(c: Char) -> Bool
  ensures: result == (c == '+' || c == '-' || c == '*' || c == '/' || c == '=' || c == '<' || c == '>' || to_int_from_char(c) == 0xB1 || c == 'x' || (to_int_from_char(c) >= 0x2200 && to_int_from_char(c) <= 0x22FF))
{
  let code = to_int_from_char(c);
  return c == '+' || c == '-' || c == '*' || c == '/' || c == '=' || c == '<' || c == '>'
      || code == 0xB1 || c == 'x'
      || (code >= 0x2200 && code <= 0x22FF);
}

// Returns true if `c` falls within basic emoji code point ranges.
// Covers emoticons, miscellaneous symbols, transport, supplemental symbols.
pub fn is_emoji(c: Char) -> Bool
  ensures: result == ((to_int_from_char(c) >= 0x1F600 && to_int_from_char(c) <= 0x1F64F) || (to_int_from_char(c) >= 0x1F300 && to_int_from_char(c) <= 0x1F5FF) || (to_int_from_char(c) >= 0x1F680 && to_int_from_char(c) <= 0x1F6FF) || (to_int_from_char(c) >= 0x1F900 && to_int_from_char(c) <= 0x1F9FF))
{
  let code = to_int_from_char(c);
  return (code >= 0x1F600 && code <= 0x1F64F)    // Emoticons
      || (code >= 0x1F300 && code <= 0x1F5FF)    // Misc symbols & pictographs
      || (code >= 0x1F680 && code <= 0x1F6FF)    // Transport & map
      || (code >= 0x1F900 && code <= 0x1F9FF);    // Supplemental symbols
}

// Returns true if `c` is a combining diacritical mark (U+0300..U+036F).
pub fn is_combining_mark(c: Char) -> Bool
  ensures: result == (to_int_from_char(c) >= 0x0300 && to_int_from_char(c) <= 0x036F)
{
  let code = to_int_from_char(c);
  return code >= 0x0300 && code <= 0x036F;
}

// -- Case --

// Returns the title-case version of `c`. For a single character this is
// equivalent to to_uppercase.
pub fn to_title_case(c: Char) -> Char {
  to_uppercase(c)
}

// -- ASCII Subclassifications --

// Returns true if `c` is an ASCII letter (a-z, A-Z).
pub fn is_ascii_letter(c: Char) -> Bool
  ensures: result == is_alphabetic(c)
{
  is_alphabetic(c)
}

// Returns true if `c` is an ASCII digit (0-9). Alias for is_digit.
pub fn is_ascii_digit(c: Char) -> Bool
  ensures: result == is_digit(c)
{
  is_digit(c)
}

// Returns true if `c` is an ASCII hexadecimal digit (0-9, a-f, A-F).
pub fn is_ascii_hex_digit(c: Char) -> Bool
  ensures: result == is_hex_digit(c)
{
  is_hex_digit(c)
}

// Returns true if `c` is ASCII punctuation (codes 33-47, 58-64, 91-96, 123-126).
pub fn is_ascii_punctuation(c: Char) -> Bool
  ensures: result == is_punctuation(c)
{
  is_punctuation(c)
}

// Returns true if `c` is ASCII whitespace (space, tab, newline, carriage return).
pub fn is_ascii_whitespace(c: Char) -> Bool
  ensures: result == is_whitespace(c)
{
  is_whitespace(c)
}

// Returns true if `c` is an ASCII control character (codes 0-31 or 127).
pub fn is_ascii_control(c: Char) -> Bool
  ensures: result == is_control(c)
{
  is_control(c)
}

// Returns true if `c` is an ASCII graphic character (codes 33-126, visible + space).
pub fn is_ascii_graphic(c: Char) -> Bool
  ensures: result == (to_int_from_char(c) >= 33 && to_int_from_char(c) <= 126)
{
  let code = to_int_from_char(c);
  return code >= 33 && code <= 126;
}

// Returns true if `c` is an ASCII printable character (codes 32-126, includes space).
pub fn is_ascii_printable(c: Char) -> Bool
  ensures: result == (to_int_from_char(c) >= 32 && to_int_from_char(c) <= 126)
{
  let code = to_int_from_char(c);
  return code >= 32 && code <= 126;
}

// -- Digit Value Conversion --

// Returns the numeric value (0-9) of a digit character, or None if `c` is not a digit.
pub fn char_to_digit_value(c: Char) -> Option[Int] {
  to_digit(c, 10)
}

// Returns the character representation of a single digit value `n` (0-9), or None if out of range.
pub fn digit_value_to_char(n: Int) -> Option[Char] {
  from_digit(n, 10)
}

// -- ASCII Case --

// Returns true if `c` is an uppercase ASCII letter (A-Z).
pub fn is_uppercase_ascii(c: Char) -> Bool
  ensures: result == is_uppercase(c)
{
  is_uppercase(c)
}

// Returns true if `c` is a lowercase ASCII letter (a-z).
pub fn is_lowercase_ascii(c: Char) -> Bool
  ensures: result == is_lowercase(c)
{
  is_lowercase(c)
}

// Returns the ASCII uppercase version of `c`. If `c` is not a lowercase ASCII letter,
// it is returned unchanged.
pub fn to_ascii_upper(c: Char) -> Char
  ensures: result == to_uppercase(c)
{
  to_uppercase(c)
}

// Returns the ASCII lowercase version of `c`. If `c` is not an uppercase ASCII letter,
// it is returned unchanged.
pub fn to_ascii_lower(c: Char) -> Char
  ensures: result == to_lowercase(c)
{
  to_lowercase(c)
}

// -- Composite Predicates --

// Returns true if `c` is whitespace or a Unicode separator character.
// Covers ASCII whitespace + line/paragraph separators (U+2028, U+2029).
pub fn is_whitespace_or_separator(c: Char) -> Bool
  ensures: result == (is_whitespace(c) || to_int_from_char(c) == 0x2028 || to_int_from_char(c) == 0x2029)
{
  if is_whitespace(c) {
    return true;
  };
  let code = to_int_from_char(c);
  return code == 0x2028 || code == 0x2029;
}
