// XIOM - Conversion: Utf8
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.utf8

// Depends on: none

// ============================================================================
// UTF-8 encoding/decoding and validation. Character encoding delegates to the
// canonical xiom.char.encode_utf8 (different function name -- safe); decoding
// and validation are implemented locally over raw bytes.
// ============================================================================

use xiom.char;
use xiom.string;

/// Encode a character as UTF-8 bytes.
/// Parameters: c -- the character.
/// Returns: 1-4 bytes forming the UTF-8 encoding of c.
/// Complexity: O(1).
pub fn utf8_encode(c: Char) -> Vec[UInt8] {
  var buf = Vec[UInt8].new();
  char.encode_utf8(c, &buf);
  return buf;
}

/// Decode one UTF-8 character from the start of a byte vector.
/// Parameters: bytes -- a UTF-8 byte sequence.
/// Returns: Some(Char) when the leading sequence is well-formed (including
///          overlong/surrogate/range checks); None otherwise.
/// Complexity: O(1).
pub fn utf8_decode(bytes: &Vec[UInt8]) -> Option[Char] {
  let len = bytes.len();
  if len == 0 {
    return None;
  }
  let b0 = bytes[0] as Int;
  var clen: Int = 0;
  if b0 <= 0x7F {
    clen = 1;
  } elif (b0 & 0xE0) == 0xC0 {
    clen = 2;
  } elif (b0 & 0xF0) == 0xE0 {
    clen = 3;
  } elif (b0 & 0xF8) == 0xF0 {
    clen = 4;
  } else {
    return None;
  }
  if clen > len {
    return None;
  }
  var cp: Int = 0;
  if clen == 1 {
    cp = b0;
  } elif clen == 2 {
    let b1 = bytes[1] as Int;
    if (b1 & 0xC0) != 0x80 { return None; }
    cp = ((b0 & 0x1F) << 6) | (b1 & 0x3F);
    if cp < 0x80 { return None; }
  } elif clen == 3 {
    let b1 = bytes[1] as Int;
    let b2 = bytes[2] as Int;
    if (b1 & 0xC0) != 0x80 { return None; }
    if (b2 & 0xC0) != 0x80 { return None; }
    cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
    if cp < 0x800 { return None; }
    if cp >= 0xD800 && cp <= 0xDFFF { return None; }
  } else {
    let b1 = bytes[1] as Int;
    let b2 = bytes[2] as Int;
    let b3 = bytes[3] as Int;
    if (b1 & 0xC0) != 0x80 { return None; }
    if (b2 & 0xC0) != 0x80 { return None; }
    if (b3 & 0xC0) != 0x80 { return None; }
    cp = ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
    if cp < 0x10000 { return None; }
    if cp > 0x10FFFF { return None; }
  }
  return Some(to_char(cp));
}

/// Check that a string is well-formed UTF-8.
/// Parameters: s -- the string to validate.
/// Returns: true when every byte sequence decodes cleanly.
/// Complexity: O(n), n = byte length.
pub fn utf8_validate(s: Str) -> Bool {
  let len = s.len();
  var i: Int = 0;
  while i < len {
    var b0 = s.byte_at(i) as Int;
    b0 = b0 & 0xFF;
    var clen: Int = 0;
    if b0 <= 0x7F {
      clen = 1;
    } elif (b0 & 0xE0) == 0xC0 {
      clen = 2;
    } elif (b0 & 0xF0) == 0xE0 {
      clen = 3;
    } elif (b0 & 0xF8) == 0xF0 {
      clen = 4;
    } else {
      return false;
    }
    if i + clen > len {
      return false;
    }
    if !_valid_sequence(s, i, clen) {
      return false;
    }
    i = i + clen;
  }
  return true;
}

/// Count the valid UTF-8 sequences in a string. Invalid bytes advance one
/// position without being counted.
/// Parameters: s -- the string to scan.
/// Returns: the number of well-formed UTF-8 sequences.
/// Complexity: O(n), n = byte length.
pub fn utf8_valid_sequences(s: Str) -> Int {
  let len = s.len();
  var count: Int = 0;
  var i: Int = 0;
  while i < len {
    var b0 = s.byte_at(i) as Int;
    b0 = b0 & 0xFF;
    var clen: Int = 0;
    if b0 <= 0x7F {
      clen = 1;
    } elif (b0 & 0xE0) == 0xC0 {
      clen = 2;
    } elif (b0 & 0xF0) == 0xE0 {
      clen = 3;
    } elif (b0 & 0xF8) == 0xF0 {
      clen = 4;
    } else {
      clen = 0;
    }
    if clen > 0 && i + clen <= len && _valid_sequence(s, i, clen) {
      count = count + 1;
      i = i + clen;
    } else {
      i = i + 1;
    }
  }
  return count;
}

// Validate the multi-byte sequence starting at byte i of length clen (2..4):
// continuation bytes plus overlong/surrogate/range checks. Single-byte
// sequences are always valid (caller already bounds-checked clen).
fn _valid_sequence(s: Str, i: Int, clen: Int) -> Bool {
  var b0 = s.byte_at(i) as Int;
    b0 = b0 & 0xFF;
  if clen == 1 {
    return true;
  }
  var cp: Int = 0;
  if clen == 2 {
    var b1 = s.byte_at(i + 1) as Int;
    b1 = b1 & 0xFF;
    if (b1 & 0xC0) != 0x80 { return false; }
    cp = ((b0 & 0x1F) << 6) | (b1 & 0x3F);
    if cp < 0x80 { return false; }
  } elif clen == 3 {
    var b1 = s.byte_at(i + 1) as Int;
    b1 = b1 & 0xFF;
    var b2 = s.byte_at(i + 2) as Int;
    b2 = b2 & 0xFF;
    if (b1 & 0xC0) != 0x80 { return false; }
    if (b2 & 0xC0) != 0x80 { return false; }
    cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
    if cp < 0x800 { return false; }
    if cp >= 0xD800 && cp <= 0xDFFF { return false; }
  } else {
    var b1 = s.byte_at(i + 1) as Int;
    b1 = b1 & 0xFF;
    var b2 = s.byte_at(i + 2) as Int;
    b2 = b2 & 0xFF;
    var b3 = s.byte_at(i + 3) as Int;
    b3 = b3 & 0xFF;
    if (b1 & 0xC0) != 0x80 { return false; }
    if (b2 & 0xC0) != 0x80 { return false; }
    if (b3 & 0xC0) != 0x80 { return false; }
    cp = ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
    if cp < 0x10000 { return false; }
    if cp > 0x10FFFF { return false; }
  }
  return true;
}


