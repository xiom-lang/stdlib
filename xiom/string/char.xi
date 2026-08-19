// XIOM — Character Operations
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.char

pub fn is_alphabetic(c: Char) -> Bool {
  let code = to_int_from_char(c);
  return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
}

pub fn is_alphanumeric(c: Char) -> Bool {
  return is_alphabetic(c) || is_digit(c);
}

pub fn is_ascii(c: Char) -> Bool {
  let code = to_int_from_char(c);
  return code <= 127;
}

pub fn is_control(c: Char) -> Bool {
  let code = to_int_from_char(c);
  return (code >= 0 && code <= 31) || code == 127;
}

pub fn is_digit(c: Char) -> Bool {
  let code = to_int_from_char(c);
  return code >= 48 && code <= 57;
}

pub fn is_lowercase(c: Char) -> Bool {
  let code = to_int_from_char(c);
  return code >= 97 && code <= 122;
}

pub fn is_uppercase(c: Char) -> Bool {
  let code = to_int_from_char(c);
  return code >= 65 && code <= 90;
}

pub fn is_numeric(c: Char) -> Bool {
  return is_digit(c);
}

pub fn is_punctuation(c: Char) -> Bool {
  let code = to_int_from_char(c);
  return (code >= 33 && code <= 47)
      || (code >= 58 && code <= 64)
      || (code >= 91 && code <= 96)
      || (code >= 123 && code <= 126);
}

pub fn is_whitespace(c: Char) -> Bool {
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

pub fn len_utf8(c: Char) -> Int {
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

// ──────────────────────────────────────────────────
//  Extended Character Functions
// ──────────────────────────────────────────────────

// ── Aliases & Shorthands ──

// Alias for is_alphabetic. Returns true if `c` is an ASCII letter (a-z, A-Z).
pub fn is_letter(c: Char) -> Bool {
  is_alphabetic(c)
}

// Alias for is_control. Returns true if `c` is a C0 control character or DEL.
pub fn is_control_char(c: Char) -> Bool {
  is_control(c)
}

// ── Digit Classification ──

// Returns true if `c` is a hexadecimal digit (0-9, a-f, A-F).
pub fn is_hex_digit(c: Char) -> Bool {
  let code = to_int_from_char(c);
  return (code >= 48 && code <= 57) || (code >= 65 && code <= 70) || (code >= 97 && code <= 102);
}

// Returns true if `c` is a binary digit ('0' or '1').
pub fn is_binary_digit(c: Char) -> Bool {
  c == '0' || c == '1'
}

// Returns true if `c` is an octal digit ('0' through '7').
pub fn is_octal_digit(c: Char) -> Bool {
  c >= '0' && c <= '7'
}

// ── Unicode Categories ──

// Returns true if `c` is a symbol character (punctuation, currency, math, or modifier).
// Covers ASCII punctuation + common Unicode symbol ranges.
pub fn is_symbol(c: Char) -> Bool {
  let code = to_int_from_char(c);
  if is_currency(c) { return true; };
  if is_math_symbol(c) { return true; };
  return is_punctuation(c)
      || (code >= 0x00A0 && code <= 0x00BF)    // Latin-1 supplement symbols
      || (code >= 0x00D7 && code <= 0x00F7)    // ×, ÷
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
// Covers $, ¢, £, ¤, ¥, and the currency symbols block U+20A0..U+20CF.
pub fn is_currency(c: Char) -> Bool {
  let code = to_int_from_char(c);
  return c == '$' || c == '¢' || c == '£' || c == '¤' || c == '¥'
      || (code >= 0x20A0 && code <= 0x20CF);
}

// Returns true if `c` is a mathematical symbol.
// Covers +, -, *, /, =, <, >, and the mathematical operators block U+2200..U+22FF.
pub fn is_math_symbol(c: Char) -> Bool {
  let code = to_int_from_char(c);
  return c == '+' || c == '-' || c == '*' || c == '/' || c == '=' || c == '<' || c == '>'
      || c == '±' || c == '×' || c == '÷'
      || (code >= 0x2200 && code <= 0x22FF);
}

// Returns true if `c` falls within basic emoji code point ranges.
// Covers emoticons, miscellaneous symbols, transport, supplemental symbols.
pub fn is_emoji(c: Char) -> Bool {
  let code = to_int_from_char(c);
  return (code >= 0x1F600 && code <= 0x1F64F)    // Emoticons
      || (code >= 0x1F300 && code <= 0x1F5FF)    // Misc symbols & pictographs
      || (code >= 0x1F680 && code <= 0x1F6FF)    // Transport & map
      || (code >= 0x1F900 && code <= 0x1F9FF);    // Supplemental symbols
}

// Returns true if `c` is a combining diacritical mark (U+0300..U+036F).
pub fn is_combining_mark(c: Char) -> Bool {
  let code = to_int_from_char(c);
  return code >= 0x0300 && code <= 0x036F;
}

// ── Case ──

// Returns the title-case version of `c`. For a single character this is
// equivalent to to_uppercase.
pub fn to_title_case(c: Char) -> Char {
  to_uppercase(c)
}

// ── ASCII Subclassifications ──

// Returns true if `c` is an ASCII letter (a-z, A-Z).
pub fn is_ascii_letter(c: Char) -> Bool {
  is_alphabetic(c)
}

// Returns true if `c` is an ASCII digit (0-9). Alias for is_digit.
pub fn is_ascii_digit(c: Char) -> Bool {
  is_digit(c)
}

// Returns true if `c` is an ASCII hexadecimal digit (0-9, a-f, A-F).
pub fn is_ascii_hex_digit(c: Char) -> Bool {
  is_hex_digit(c)
}

// Returns true if `c` is ASCII punctuation (codes 33-47, 58-64, 91-96, 123-126).
pub fn is_ascii_punctuation(c: Char) -> Bool {
  is_punctuation(c)
}

// Returns true if `c` is ASCII whitespace (space, tab, newline, carriage return).
pub fn is_ascii_whitespace(c: Char) -> Bool {
  is_whitespace(c)
}

// Returns true if `c` is an ASCII control character (codes 0-31 or 127).
pub fn is_ascii_control(c: Char) -> Bool {
  is_control(c)
}

// Returns true if `c` is an ASCII graphic character (codes 33-126, visible + space).
pub fn is_ascii_graphic(c: Char) -> Bool {
  let code = to_int_from_char(c);
  return code >= 33 && code <= 126;
}

// Returns true if `c` is an ASCII printable character (codes 32-126, includes space).
pub fn is_ascii_printable(c: Char) -> Bool {
  let code = to_int_from_char(c);
  return code >= 32 && code <= 126;
}

// ── Digit Value Conversion ──

// Returns the numeric value (0-9) of a digit character, or None if `c` is not a digit.
pub fn char_to_digit_value(c: Char) -> Option[Int] {
  to_digit(c, 10)
}

// Returns the character representation of a single digit value `n` (0-9), or None if out of range.
pub fn digit_value_to_char(n: Int) -> Option[Char] {
  from_digit(n, 10)
}

// ── ASCII Case ──

// Returns true if `c` is an uppercase ASCII letter (A-Z).
pub fn is_uppercase_ascii(c: Char) -> Bool {
  is_uppercase(c)
}

// Returns true if `c` is a lowercase ASCII letter (a-z).
pub fn is_lowercase_ascii(c: Char) -> Bool {
  is_lowercase(c)
}

// Returns the ASCII uppercase version of `c`. If `c` is not a lowercase ASCII letter,
// it is returned unchanged.
pub fn to_ascii_upper(c: Char) -> Char {
  to_uppercase(c)
}

// Returns the ASCII lowercase version of `c`. If `c` is not an uppercase ASCII letter,
// it is returned unchanged.
pub fn to_ascii_lower(c: Char) -> Char {
  to_lowercase(c)
}

// ── Composite Predicates ──

// Returns true if `c` is whitespace or a Unicode separator character.
// Covers ASCII whitespace + line/paragraph separators (U+2028, U+2029).
pub fn is_whitespace_or_separator(c: Char) -> Bool {
  if is_whitespace(c) {
    return true;
  };
  let code = to_int_from_char(c);
  return code == 0x2028 || code == 0x2029;
}
