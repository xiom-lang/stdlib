// XIOM - Conversion: Mac
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.mac

// Depends on: xiom.rand

// ============================================================================
// MAC address parsing, serialization, and validation helpers. Random MACs
// use a local LCG seeded from the system clock (the canonical xiom.rand
// cannot be imported here because it pulls xiom.crypto, which references an
// undefined _pkcs7_pad symbol at link time); the locally-administered unicast
// bit is set on the first octet.
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

/// Parse a MAC address into six octets.
/// Parameters: s — a MAC address using ':' or '-' separators
///          (e.g. "aa:bb:cc:dd:ee:ff" or "AA-BB-CC-DD-EE-FF").
/// Returns: Some(six octets) for a well-formed address, None otherwise.
/// Complexity: O(1).
pub fn mac_parse(s: Str) -> Option[Vec[UInt8]] {
  if string.str_len(s) != 17 {
    return None;
  }
  var result = Vec[UInt8].new();
  var i: Int = 0;
  while i < 6 {
    var offset = i * 3;
    if i > 0 {
      var sep = string.byte_at(s, offset - 1);
      if sep != 58 && sep != 45 {
        return None;
      }
    }
    var hi = _hex_val(string.byte_at(s, offset));
    var lo = _hex_val(string.byte_at(s, offset + 1));
    if hi < 0 || lo < 0 {
      return None;
    }
    result.push(((hi << 4) | lo) as UInt8);
    i = i + 1;
  }
  return Some(result);
}

/// Format six octets as a colon-separated lowercase MAC address.
/// Parameters: bytes — at least six octets (only the first six are used).
/// Returns: the "xx:xx:xx:xx:xx:xx" representation.
/// Complexity: O(1).
pub fn mac_to_string(bytes: &Vec[UInt8]) -> Str {
  var result = "";
  var i: Int = 0;
  while i < 6 && i < bytes.len() {
    if i > 0 {
      result = string.str_concat(result, ":");
    }
    var b = bytes[i] as Int;
    b = b & 0xFF;
    result = string.str_concat(result, _hex_digit((b >> 4) & 0x0F));
    result = string.str_concat(result, _hex_digit(b & 0x0F));
    i = i + 1;
  }
  return result;
}

/// Check that a string is a valid MAC address (six hex octets, ':' or '-'
/// separators).
/// Parameters: s — the candidate string.
/// Returns: true when well-formed.
/// Complexity: O(1).
pub fn mac_is_valid(s: Str) -> Bool {
  var opt = mac_parse(s);
  return opt.is_some;
}

/// Generate a random MAC address string (locally administered, unicast).
/// Returns: a 17-character MAC address.
/// Complexity: O(1).
pub fn mac_random() -> Str {
  var bytes = Vec[UInt8].new();
  var i: Int = 0;
  while i < 6 {
    bytes.push(_next_byte());
    i = i + 1;
  }
  var first = bytes[0] as Int;
  first = first & 0xFE;
  first = first | 0x02;
  bytes[0] = first as UInt8;
  return mac_to_string(&bytes);
}

fn _hex_val(b: UInt8) -> Int {
  var v = b as Int;
  if v >= 48 && v <= 57 {
    return v - 48;
  }
  if v >= 97 && v <= 102 {
    return v - 87;
  }
  if v >= 65 && v <= 70 {
    return v - 55;
  }
  return -1;
}

fn _hex_digit(d: Int) -> Str {
  if d < 10 {
    return string.str_slice("0123456789", d, d + 1);
  }
  return string.str_slice("abcdef", d - 10, d - 9);
}
