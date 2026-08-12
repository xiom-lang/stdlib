// XIOM - Conversion: Uuid
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.uuid

// Depends on: xiom.rand

// ============================================================================
// UUID v4 generation and parsing helpers. The canonical xiom.rand.random_bytes
// would be the preferred RNG source, but importing xiom.rand pulls xiom.crypto
// (which references an undefined _pkcs7_pad symbol at link time), so a local
// LCG seeded from the system clock is used instead; the v4 byte layout,
// string formatting, and validation are implemented locally.
// ============================================================================

use xiom.string;

extern "C" {
  fn clock() -> Int;
}

var _state: Int = 0;
var _seeded = false;

// Advance the LCG and return the next pseudo-random byte.
fn _next_byte() -> UInt8 {
  if !_seeded {
    var t = clock();
    if t == 0 {
      t = 12345;
    } elif t < 0 {
      t = -t;
    }
    _state = t;
    _seeded = true;
  }
  var s = (_state * 48271) % 2147483647;
  if s <= 0 {
    s = s + 2147483647;
  }
  _state = s;
  return ((_state >> 16) & 0xFF) as UInt8;
}

// Fill a vector with `count` pseudo-random bytes.
fn _random_bytes(count: Int) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i: Int = 0;
  while i < count {
    result.push(_next_byte());
    i = i + 1;
  }
  return result;
}

/// Generate a random RFC 4122 version 4 UUID string (8-4-4-4-12, lowercase).
/// Returns: a 36-character UUID string.
/// Complexity: O(1).
pub fn uuid_v4() -> Str {
  var bytes = _random_bytes(16);
  var b6 = bytes[6] as Int;
  var b8 = bytes[8] as Int;
  b6 = (b6 & 0x0F) | 0x40;
  b8 = (b8 & 0x3F) | 0x80;
  bytes[6] = b6 as UInt8;
  bytes[8] = b8 as UInt8;
  return _format_uuid(&bytes);
}

/// Parse a UUID string into its four 32-bit fields.
/// Parameters: s â€” a UUID string in 8-4-4-4-12 form.
/// Returns: Some((time_low, time_mid, time_hi_and_version, clock_and_node))
///          for a well-formed string, None otherwise.
/// Complexity: O(1).
pub fn uuid_parse(s: Str) -> Option[(Int, Int, Int, Int)] {
  if !uuid_is_valid(s) {
    return None;
  }
  var v0 = _hex4(string.str_slice(s, 0, 8));
  var v1 = _hex4(string.str_slice(s, 9, 13));
  var v2 = _hex4(string.str_slice(s, 14, 18));
  var hi = _hex4(string.str_slice(s, 19, 23));
  var lo = _hex4(string.str_slice(s, 24, 36));
  var v3 = (hi << 16) | lo;
  return Some((v0, v1, v2, v3));
}

/// Check that a string is a valid UUID (36 chars, 8-4-4-4-12 layout, hex).
/// Parameters: s â€” the candidate string.
/// Returns: true when the layout matches.
/// Complexity: O(1).
pub fn uuid_is_valid(s: Str) -> Bool {
  if string.str_len(s) != 36 {
    return false;
  }
  if string.byte_at(s, 8) != 45 {
    return false;
  }
  if string.byte_at(s, 13) != 45 {
    return false;
  }
  if string.byte_at(s, 18) != 45 {
    return false;
  }
  if string.byte_at(s, 23) != 45 {
    return false;
  }
  var i: Int = 0;
  while i < 36 {
    if i == 8 || i == 13 || i == 18 || i == 23 {
      i = i + 1;
    } else {
      var b = string.byte_at(s, i);
      if !_is_hex(b) {
        return false;
      }
      i = i + 1;
    }
  }
  return true;
}

/// Generate the raw 16 bytes of a random RFC 4122 version 4 UUID.
/// Returns: 16 bytes with the version (0100) and variant (10) bits set.
/// Complexity: O(1).
pub fn uuid_v4_bytes() -> Vec[UInt8] {
  var bytes = _random_bytes(16);
  var b6 = bytes[6] as Int;
  var b8 = bytes[8] as Int;
  b6 = (b6 & 0x0F) | 0x40;
  b8 = (b8 & 0x3F) | 0x80;
  bytes[6] = b6 as UInt8;
  bytes[8] = b8 as UInt8;
  return bytes;
}

// Format 16 bytes as a lowercase 8-4-4-4-12 UUID string.
fn _format_uuid(bytes: &Vec[UInt8]) -> Str {
  var result = "";
  var i: Int = 0;
  while i < 16 {
    if i == 4 || i == 6 || i == 8 || i == 10 {
      result = string.str_concat(result, "-");
    }
    var b = bytes[i] as Int;
    b = b & 0xFF;
    result = string.str_concat(result, _hex_digit((b >> 4) & 0x0F));
    result = string.str_concat(result, _hex_digit(b & 0x0F));
    i = i + 1;
  }
  return result;
}

// Parse an even-length hex string into an Int.
fn _hex4(s: Str) -> Int {
  var v: Int = 0;
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    var d: Int = -1;
    if b >= 48 && b <= 57 {
      d = (b as Int) - 48;
    } elif b >= 97 && b <= 102 {
      d = (b as Int) - 87;
    } elif b >= 65 && b <= 70 {
      d = (b as Int) - 55;
    }
    if d < 0 {
      return -1;
    }
    v = v * 16 + d;
    i = i + 1;
  }
  return v;
}

fn _is_hex(b: UInt8) -> Bool {
  var v = b as Int;
  if v >= 48 && v <= 57 {
    return true;
  }
  if v >= 97 && v <= 102 {
    return true;
  }
  if v >= 65 && v <= 70 {
    return true;
  }
  return false;
}

fn _hex_digit(d: Int) -> Str {
  if d < 10 {
    return string.str_slice("0123456789", d, d + 1);
  }
  return string.str_slice("abcdef", d - 10, d - 9);
}

