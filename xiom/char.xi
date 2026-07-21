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
  requires: 2 <= radix && radix <= 36
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
  requires: 2 <= radix && radix <= 36
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
