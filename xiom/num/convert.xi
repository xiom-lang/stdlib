// XIOM -- Numeric Base Conversion (xiom.num.convert)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Pure numeric conversion helpers: Base58/Base62 encoders and decoders,
// Adobe ASCII85 encoding/decoding, and Roman numeral conversion. All
// functions are pure (no I/O) and operate on Int.

module xiom.num.convert

use xiom.string;
use xiom.core.INT_MAX;

const BASE58_ALPHABET: Str = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
const BASE62_ALPHABET: Str = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
const A85_ALPHABET: Str = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_\x60abcdefghijklmnopqrstuvwxyz";

pub fn to_base58(n: Int) -> Str {
  if n == 0 {
    return "1";
  }
  var neg = false;
  var num = n;
  if num < 0 {
    neg = true;
    num = -num;
  }
  var digits = Vec[Int].new();
  while num > 0 {
    digits.push(num % 58);
    num = num / 58;
  }
  var result = "";
  if neg {
    result = "-";
  }
  var i = digits.len() - 1;
  while i >= 0 {
    var d = digits[i];
    var ch = string.str_slice(BASE58_ALPHABET, d, d + 1);
    result = result + ch;
    i = i - 1;
  }
  result
}

fn base58_digit(c: UInt8) -> Int {
  var i = 0;
  while i < 58 {
    if string.byte_at(BASE58_ALPHABET, i) == c {
      return i;
    }
    i = i + 1;
  }
  -1
}

pub fn from_base58(s: Str) -> Option[Int] {
  if s.len() == 0 {
    return None;
  }
  var neg = false;
  var i = 0;
  var first = string.byte_at(s, 0);
  if first == 45 {
    neg = true;
    i = 1;
  } elif first == 43 {
    i = 1;
  }
  if i >= s.len() {
    return None;
  }
  var result: Int = 0;
  while i < s.len() {
    var digit = base58_digit(string.byte_at(s, i));
    if digit < 0 {
      return None;
    }
    if result > (INT_MAX - digit) / 58 {
      return None;
    }
    result = result * 58 + digit;
    i = i + 1;
  }
  if neg {
    result = -result;
  }
  Some(result)
}

// -- Base62 ------------------------------------------------------------------

/// Converts an integer to its Base62 representation ("0-9A-Za-z").
/// n == 0 yields "0". Negative numbers get a '-' prefix.
/// Complexity: O(log_62 n).
pub fn to_base62(n: Int) -> Str {
  if n == 0 {
    return "0";
  }
  var neg = false;
  var num = n;
  if num < 0 {
    neg = true;
    num = -num;
  }
  var digits = Vec[Int].new();
  while num > 0 {
    digits.push(num % 62);
    num = num / 62;
  }
  var result = "";
  if neg {
    result = "-";
  }
  var i = digits.len() - 1;
  while i >= 0 {
    var d = digits[i];
    var ch = string.str_slice(BASE62_ALPHABET, d, d + 1);
    result = result + ch;
    i = i - 1;
  }
  result
}

fn base62_digit(c: UInt8) -> Int {
  var code = c as Int;
  if code >= 48 && code <= 57 {
    return code - 48;
  }
  if code >= 65 && code <= 90 {
    return code - 55;
  }
  if code >= 97 && code <= 122 {
    return code - 61;
  }
  -1
}

/// Parses a Base62 string back into an integer. Returns None on invalid
/// characters, overflow, or an empty string. An optional leading '-'/'+'
/// is accepted.
/// Complexity: O(n).
pub fn from_base62(s: Str) -> Option[Int] {
  if s.len() == 0 {
    return None;
  }
  var neg = false;
  var i = 0;
  var first = string.byte_at(s, 0);
  if first == 45 {
    neg = true;
    i = 1;
  } elif first == 43 {
    i = 1;
  }
  if i >= s.len() {
    return None;
  }
  var result: Int = 0;
  while i < s.len() {
    var digit = base62_digit(string.byte_at(s, i));
    if digit < 0 {
      return None;
    }
    if result > (INT_MAX - digit) / 62 {
      return None;
    }
    result = result * 62 + digit;
    i = i + 1;
  }
  if neg {
    result = -result;
  }
  Some(result)
}

// -- ASCII85 (Adobe) ---------------------------------------------------------

/// Encodes a 32-bit big-endian value as exactly five ASCII85 characters
/// ('!'..'u').
fn encode_a85_group(value: Int) -> Str {
  var v = value;
  var d4 = v % 85;
  v = v / 85;
  var d3 = v % 85;
  v = v / 85;
  var d2 = v % 85;
  v = v / 85;
  var d1 = v % 85;
  v = v / 85;
  var d0 = v % 85;
  var result = "";
  result = result + string.str_slice(A85_ALPHABET, d0, d0 + 1);
  result = result + string.str_slice(A85_ALPHABET, d1, d1 + 1);
  result = result + string.str_slice(A85_ALPHABET, d2, d2 + 1);
  result = result + string.str_slice(A85_ALPHABET, d3, d3 + 1);
  result = result + string.str_slice(A85_ALPHABET, d4, d4 + 1);
  result
}

pub fn to_ascii85(data: &Vec[UInt8]) -> Str {
  var result = "";
  var len = data.len();
  if len == 0 {
    return result;
  }
  var i = 0;
  while i < len {
    var remaining = len - i;
    if remaining >= 4 {
      var value = ((data[i] as Int) << 24) | ((data[i + 1] as Int) << 16) | ((data[i + 2] as Int) << 8) | (data[i + 3] as Int);
      if value == 0 {
        result = result + "z";
      } else {
        result = result + encode_a85_group(value);
      }
      i = i + 4;
    } else {
      var b0 = data[i] as Int;
      var b1 = 0;
      var b2 = 0;
      if remaining >= 2 {
        b1 = data[i + 1] as Int;
      }
      if remaining >= 3 {
        b2 = data[i + 2] as Int;
      }
      var value = (b0 << 24) | (b1 << 16) | (b2 << 8);
      var group = encode_a85_group(value);
      result = result + string.str_slice(group, 0, remaining + 1);
      i = i + remaining;
    }
  }
  result
}

fn a85_digit(c: UInt8) -> Int {
  var code = c as Int;
  if code < 33 || code > 117 {
    return -1;
  }
  code - 33
}

pub fn from_ascii85(s: Str) -> Option[Vec[UInt8]] {
  var result = Vec[UInt8].new();
  var len = s.len();
  if len == 0 {
    return Some(result);
  }
  var i = 0;
  while i < len {
    var c = string.byte_at(s, i);
    if c == 122 {
      result.push(0);
      result.push(0);
      result.push(0);
      result.push(0);
      i = i + 1;
    } else {
      var value: Int = 0;
      var count = 0;
      while count < 5 && i < len {
        var ch = string.byte_at(s, i);
        if ch == 122 {
          return None;
        }
        var digit = a85_digit(ch);
        if digit < 0 {
          return None;
        }
        value = value * 85 + digit;
        count = count + 1;
        i = i + 1;
      }
      var pos = count;
      while pos < 5 {
        value = value * 85 + 84;
        pos = pos + 1;
      }
      if count == 5 && value > 4294967295 {
        return None;
      }
      if count == 5 {
        result.push((value >> 24) as UInt8);
        result.push((value >> 16) as UInt8);
        result.push((value >> 8) as UInt8);
        result.push(value as UInt8);
      } elif count == 4 {
        result.push((value >> 24) as UInt8);
        result.push((value >> 16) as UInt8);
        result.push((value >> 8) as UInt8);
      } elif count == 3 {
        result.push((value >> 24) as UInt8);
        result.push((value >> 16) as UInt8);
      } elif count == 2 {
        result.push((value >> 24) as UInt8);
      } else {
        return None;
      }
    }
  }
  Some(result)
}

fn roman_value(c: UInt8) -> Int {
  if c == 73 { return 1; }       // I
  if c == 86 { return 5; }       // V
  if c == 88 { return 10; }      // X
  if c == 76 { return 50; }      // L
  if c == 67 { return 100; }     // C
  if c == 68 { return 500; }     // D
  if c == 77 { return 1000; }    // M
  -1
}

pub fn to_roman(n: Int) -> Option[Str] {
  if n <= 0 || n > 3999 {
    return None;
  }
  var values = Vec[Int].new();
  values.push(1000);
  values.push(900);
  values.push(500);
  values.push(400);
  values.push(100);
  values.push(90);
  values.push(50);
  values.push(40);
  values.push(10);
  values.push(9);
  values.push(5);
  values.push(4);
  values.push(1);
  var numerals = Vec[Str].new();
  numerals.push("M");
  numerals.push("CM");
  numerals.push("D");
  numerals.push("CD");
  numerals.push("C");
  numerals.push("XC");
  numerals.push("L");
  numerals.push("XL");
  numerals.push("X");
  numerals.push("IX");
  numerals.push("V");
  numerals.push("IV");
  numerals.push("I");
  var result = "";
  var remaining = n;
  var i = 0;
  while i < values.len() {
    while remaining >= values[i] {
      result = result + numerals[i];
      remaining = remaining - values[i];
    }
    i = i + 1;
  }
  Some(result)
}

pub fn from_roman(s: Str) -> Option[Int] {
  if s.len() == 0 {
    return None;
  }
  var result: Int = 0;
  var i = 0;
  while i < s.len() {
    var val = roman_value(string.byte_at(s, i));
    if val < 0 {
      return None;
    }
    if i + 1 < s.len() {
      var next = roman_value(string.byte_at(s, i + 1));
      if next < 0 {
        return None;
      }
      if next > val {
        result = result + (next - val);
        i = i + 2;
      } else {
        result = result + val;
        i = i + 1;
      }
    } else {
      result = result + val;
      i = i + 1;
    }
  }
  if result < 1 || result > 3999 {
    return None;
  }
  Some(result)
}
