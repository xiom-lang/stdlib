// XIOM - Conversion: Base62
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.base62

// Depends on: xiom.num

// ============================================================================
// Base62 (0-9, A-Z, a-z) encoding/decoding. The integer <-> base62 helpers
// mirror xiom.num.convert (implemented locally: same-name delegation crashes
// the compiler -- see xiom.convert.base58 for the probe reference).
// ============================================================================

use xiom.string;
use xiom.core.INT_MAX;
use xiom.core.INT_MIN;

const _B62_ALPHABET: Str = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

/// Decode value of a base62 character byte; -1 for an invalid character.
fn _b62_digit(c: UInt8) -> Int {
  var code = c as Int;
  code = code & 0xFF;
  if code >= 48 && code <= 57 { return code - 48; }
  if code >= 65 && code <= 90 { return code - 55; }
  if code >= 97 && code <= 122 { return code - 61; }
  -1
}

/// Converts an integer to its base62 representation ("0-9A-Za-z"). 0 yields
/// "0"; negatives get a "-" prefix. INT_MIN is rendered exactly via negative-
/// digit extraction. Complexity: O(log_62 n).
pub fn to_base62(value: Int) -> Str {
  if value == 0 {
    return "0";
  };
  var neg = false;
  var num = value;
  if num < 0 {
    neg = true;
  };
  if num > 0 {
    num = 0 - num;
  };
  var digits = Vec[Int].new();
  while num != 0 {
    var d = num % 62;
    if d < 0 {
      d = 0 - d;
    };
    digits.push(d);
    num = num / 62;
  };
  var result = "";
  if neg {
    result = "-";
  };
  var i = digits.len() - 1;
  while i >= 0 {
    var d = digits[i];
    result = string.str_concat(result, string.str_slice(_B62_ALPHABET, d, d + 1));
    i = i - 1;
  };
  result
}

/// Parses a base62 string into an Int. An optional leading '-'/'+' is
/// accepted. Returns Err on an empty string, an invalid character, or
/// overflow. Negative magnitudes accumulate in signed space, so INT_MIN
/// round-trips exactly. Complexity: O(n), n = string length.
pub fn from_base62(s: Str) -> Result[Int, Str] {
  let slen = s.len();
  if slen == 0 {
    return Err("empty base62 string");
  };
  var neg = false;
  var i: Int = 0;
  var first = string.byte_at(s, 0);
  if first == 45 {
    neg = true;
    i = 1;
  } elif first == 43 {
    i = 1;
  };
  if i >= slen {
    return Err("no base62 digits");
  };
  var result: Int = 0;
  if neg {
    while i < slen {
      var digit = _b62_digit(string.byte_at(s, i));
      if digit < 0 {
        return Err("invalid base62 character");
      };
      if result < (INT_MIN + digit) / 62 {
        return Err("base62 overflow");
      };
      result = result * 62 - digit;
      i = i + 1;
    };
  } else {
    while i < slen {
      var digit = _b62_digit(string.byte_at(s, i));
      if digit < 0 {
        return Err("invalid base62 character");
      };
      if result > (INT_MAX - digit) / 62 {
        return Err("base62 overflow");
      };
      result = result * 62 + digit;
      i = i + 1;
    };
  };
  Ok(result)
}

/// Encodes bytes as a base62 string (big-endian base-256 value written in
/// base 62). Leading zero bytes produce leading '0' characters. Empty input
/// yields "". Complexity: O(n^2) worst case.
pub fn base62_encode(data: &Vec[UInt8]) -> Str {
  let len = data.len();
  if len == 0 {
    return "";
  };
  var zeros: Int = 0;
  while zeros < len {
    var b = data[zeros] as Int;
    b = b & 0xFF;
    if b != 0 {
      break;
    };
    zeros = zeros + 1;
  };
  var n = Vec[Int].new();
  var i: Int = 0;
  while i < len {
    var b = data[i] as Int;
    b = b & 0xFF;
    n.push(b);
    i = i + 1;
  };
  var digits = Vec[Int].new();
  var start = zeros;
  var nlen = len;
  while start < nlen {
    var remainder: Int = 0;
    var j = start;
    while j < nlen {
      var acc = remainder * 256 + n[j];
      n[j] = acc / 62;
      remainder = acc % 62;
      j = j + 1;
    };
    digits.push(remainder);
    while start < nlen && n[start] == 0 {
      start = start + 1;
    };
  };
  var result = "";
  var k: Int = 0;
  while k < zeros {
    result = string.str_concat(result, "0");
    k = k + 1;
  };
  var di = digits.len() - 1;
  while di >= 0 {
    var d = digits[di];
    result = string.str_concat(result, string.str_slice(_B62_ALPHABET, d, d + 1));
    di = di - 1;
  };
  result
}

/// Decodes a base62 string back into bytes. Leading '0' characters map back
/// to leading zero bytes. Returns Err on an invalid character. Empty input
/// yields an empty byte vector. Complexity: O(n^2) worst case.
pub fn base62_decode(s: Str) -> Result[Vec[UInt8], Str] {
  var result = Vec[UInt8].new();
  let len = s.len();
  if len == 0 {
    return Ok(result);
  };
  var zeros: Int = 0;
  while zeros < len {
    var b = string.byte_at(s, zeros) as Int;
    b = b & 0xFF;
    if b != 48 {
      break;
    };
    zeros = zeros + 1;
  };
  var n = Vec[Int].new();
  var i: Int = zeros;
  while i < len {
    var v = _b62_digit(string.byte_at(s, i));
    if v < 0 {
      return Err("invalid base62 character");
    };
    n.push(v);
    i = i + 1;
  };
  var bytes = Vec[Int].new();
  var j: Int = 0;
  while j < n.len() {
    var carry = n[j];
    var k: Int = 0;
    while k < bytes.len() {
      var acc = bytes[k] * 62 + carry;
      bytes[k] = acc & 0xFF;
      carry = acc >> 8;
      k = k + 1;
    };
    while carry > 0 {
      bytes.push(carry & 0xFF);
      carry = carry >> 8;
    };
    j = j + 1;
  };
  var z: Int = 0;
  while z < zeros {
    result.push(0);
    z = z + 1;
  };
  var bi = bytes.len() - 1;
  while bi >= 0 {
    result.push(bytes[bi] as UInt8);
    bi = bi - 1;
  };
  Ok(result)
}
