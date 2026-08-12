// XIOM - Conversion: UTF-16/UTF-32
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.utf

// Depends on: xiom.string, xiom.utf8

use xiom.string;
use xiom.char;

// ============================================================================
// UTF-16 and UTF-32 conversion helpers. Covers code-unit vectors, little /
// big-endian byte serialization (with BOM), code point arithmetic, and
// surrogate pair handling. Strings are valid UTF-8 by construction, so code
// points are collected with a local byte decoder (byte_at + & 0xFF). Invalid
// input yields Err/None, never a crash.
// ============================================================================

/// Encode a string to native-order UTF-16 code units (no BOM).
/// Parameters: s â€” the input string.
/// Returns: UTF-16 code units (surrogate pairs for supplementary chars).
/// Complexity: O(n).
pub fn utf16_encode(s: Str) -> Vec[UInt16] {
  var result = Vec[UInt16].new();
  var cps = _collect_cps(s);
  var i: Int = 0;
  while i < cps.len() {
    var cp = cps[i];
    if cp < 0x10000 {
      result.push(cp as UInt16);
    } else {
      var v = cp - 0x10000;
      var hi = 0xD800 + (v >> 10);
      var lo = 0xDC00 + (v & 0x3FF);
      result.push(hi as UInt16);
      result.push(lo as UInt16);
    }
    i = i + 1;
  }
  return result;
}

/// Decode native-order UTF-16 code units to a string.
/// Parameters: bytes â€” the code units (a leading BOM is skipped).
/// Returns: Ok(Str) on success; Err for lone surrogates.
/// Complexity: O(n).
pub fn utf16_decode(bytes: &Vec[UInt16]) -> Result[Str, Str] {
  var cps = Vec[Int].new();
  var i: Int = 0;
  var n = bytes.len();
  if n > 0 && (bytes[0] as Int) == 0xFEFF {
    i = 1;
  }
  while i < n {
    var u = bytes[i] as Int;
    if u >= 0xD800 && u <= 0xDBFF {
      if i + 1 >= n {
        return Err("utf16_decode: lone high surrogate");
      }
      var lo = bytes[i + 1] as Int;
      if lo < 0xDC00 || lo > 0xDFFF {
        return Err("utf16_decode: invalid low surrogate");
      }
      var cp = 0x10000 + ((u - 0xD800) << 10) + (lo - 0xDC00);
      cps.push(cp);
      i = i + 2;
    } elif u >= 0xDC00 && u <= 0xDFFF {
      return Err("utf16_decode: lone low surrogate");
    } else {
      cps.push(u);
      i = i + 1;
    }
  }
  return Ok(_cps_to_str(&cps));
}

/// Encode a string to little-endian UTF-16 bytes including a BOM.
/// Parameters: s â€” the input string.
/// Returns: the byte sequence.
/// Complexity: O(n).
pub fn utf16le_to_bytes(s: Str) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  result.push(0xFF);
  result.push(0xFE);
  var units = utf16_encode(s);
  var i: Int = 0;
  while i < units.len() {
    var u = units[i] as Int;
    result.push((u & 0xFF) as UInt8);
    result.push(((u >> 8) & 0xFF) as UInt8);
    i = i + 1;
  }
  return result;
}

/// Encode a string to big-endian UTF-16 bytes including a BOM.
/// Parameters: s â€” the input string.
/// Returns: the byte sequence.
/// Complexity: O(n).
pub fn utf16be_to_bytes(s: Str) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  result.push(0xFE);
  result.push(0xFF);
  var units = utf16_encode(s);
  var i: Int = 0;
  while i < units.len() {
    var u = units[i] as Int;
    result.push(((u >> 8) & 0xFF) as UInt8);
    result.push((u & 0xFF) as UInt8);
    i = i + 1;
  }
  return result;
}

/// Decode little-endian UTF-16 bytes to a string.
/// Parameters: bytes â€” the byte sequence (a leading BOM is skipped).
/// Returns: Ok(Str) on success; Err for an odd length or lone surrogates.
/// Complexity: O(n).
pub fn utf16_decode_le(bytes: &Vec[UInt8]) -> Result[Str, Str] {
  if bytes.len() % 2 != 0 {
    return Err("utf16_decode_le: odd byte length");
  }
  var units = Vec[UInt16].new();
  var i: Int = 0;
  while i < bytes.len() {
    var lo = bytes[i] as Int;
    var hi = bytes[i + 1] as Int;
    units.push(((hi << 8) | lo) as UInt16);
    i = i + 2;
  }
  return utf16_decode(&units);
}

/// Decode big-endian UTF-16 bytes to a string.
/// Parameters: bytes â€” the byte sequence (a leading BOM is skipped).
/// Returns: Ok(Str) on success; Err for an odd length or lone surrogates.
/// Complexity: O(n).
pub fn utf16_decode_be(bytes: &Vec[UInt8]) -> Result[Str, Str] {
  if bytes.len() % 2 != 0 {
    return Err("utf16_decode_be: odd byte length");
  }
  var units = Vec[UInt16].new();
  var i: Int = 0;
  while i < bytes.len() {
    var hi = bytes[i] as Int;
    var lo = bytes[i + 1] as Int;
    units.push(((hi << 8) | lo) as UInt16);
    i = i + 2;
  }
  return utf16_decode(&units);
}

/// Encode a string to UTF-32 code points (no BOM).
/// Parameters: s â€” the input string.
/// Returns: one UInt32 per code point.
/// Complexity: O(n).
pub fn utf32_encode(s: Str) -> Vec[UInt32] {
  var result = Vec[UInt32].new();
  var cps = _collect_cps(s);
  var i: Int = 0;
  while i < cps.len() {
    result.push(cps[i] as UInt32);
    i = i + 1;
  }
  return result;
}

/// Decode UTF-32 code points to a string.
/// Parameters: code_points â€” the code points (a leading BOM is skipped).
/// Returns: Ok(Str) on success; Err for a surrogate or out-of-range value.
/// Complexity: O(n).
pub fn utf32_decode(code_points: &Vec[UInt32]) -> Result[Str, Str] {
  var cps = Vec[Int].new();
  var i: Int = 0;
  var n = code_points.len();
  if n > 0 && (code_points[0] as Int) == 0xFEFF {
    i = 1;
  }
  while i < n {
    var cp = code_points[i] as Int;
    if cp > 0x10FFFF {
      return Err("utf32_decode: code point exceeds maximum Unicode value");
    }
    if cp >= 0xD800 && cp <= 0xDFFF {
      return Err("utf32_decode: surrogate code point");
    }
    cps.push(cp);
    i = i + 1;
  }
  return Ok(_cps_to_str(&cps));
}

/// Encode a string to little-endian UTF-32 bytes including a BOM.
/// Parameters: s â€” the input string.
/// Returns: the byte sequence.
/// Complexity: O(n).
pub fn utf32le_to_bytes(s: Str) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  result.push(0xFF);
  result.push(0xFE);
  result.push(0x00);
  result.push(0x00);
  var cps = utf32_encode(s);
  var i: Int = 0;
  while i < cps.len() {
    var cp = cps[i] as Int;
    result.push((cp & 0xFF) as UInt8);
    result.push(((cp >> 8) & 0xFF) as UInt8);
    result.push(((cp >> 16) & 0xFF) as UInt8);
    result.push(((cp >> 24) & 0xFF) as UInt8);
    i = i + 1;
  }
  return result;
}

/// Encode a string to big-endian UTF-32 bytes including a BOM.
/// Parameters: s â€” the input string.
/// Returns: the byte sequence.
/// Complexity: O(n).
pub fn utf32be_to_bytes(s: Str) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  result.push(0x00);
  result.push(0x00);
  result.push(0xFE);
  result.push(0xFF);
  var cps = utf32_encode(s);
  var i: Int = 0;
  while i < cps.len() {
    var cp = cps[i] as Int;
    result.push(((cp >> 24) & 0xFF) as UInt8);
    result.push(((cp >> 16) & 0xFF) as UInt8);
    result.push(((cp >> 8) & 0xFF) as UInt8);
    result.push((cp & 0xFF) as UInt8);
    i = i + 1;
  }
  return result;
}

/// Report whether every code point of a string fits within UTF-16 (i.e. no
/// character lies in the surrogate range and all are <= 0x10FFFF).
/// Parameters: s â€” the input string.
/// Returns: true when every code point is encodable in UTF-16.
/// Complexity: O(n).
pub fn utf16_is_valid(s: Str) -> Bool {
  var cps = _collect_cps(s);
  var i: Int = 0;
  while i < cps.len() {
    var cp = cps[i];
    if cp < 0 {
      return false;
    }
    if cp > 0x10FFFF {
      return false;
    }
    if cp >= 0xD800 && cp <= 0xDFFF {
      return false;
    }
    i = i + 1;
  }
  return true;
}

/// Report whether a string contains no surrogate or invalid code points.
/// Parameters: s â€” the input string.
/// Returns: true when every code point is a valid scalar value.
/// Complexity: O(n).
pub fn utf32_is_valid(s: Str) -> Bool {
  return utf16_is_valid(s);
}

/// Split a code point into a UTF-16 surrogate pair.
/// Parameters: cp â€” a code point >= 0x10000.
/// Returns: (high surrogate, low surrogate). Code points below 0x10000 or
///          above 0x10FFFF map to (0, 0).
/// Complexity: O(1).
pub fn code_point_to_utf16(cp: Int) -> (UInt16, UInt16) {
  if cp < 0x10000 || cp > 0x10FFFF {
    return (0 as UInt16, 0 as UInt16);
  }
  var v = cp - 0x10000;
  var hi = 0xD800 + (v >> 10);
  var lo = 0xDC00 + (v & 0x3FF);
  return (hi as UInt16, lo as UInt16);
}

/// Combine a UTF-16 surrogate pair into a code point.
/// Parameters: hi â€” the high surrogate; lo â€” the low surrogate.
/// Returns: the code point; -1 when the pair is not a valid surrogate pair.
/// Complexity: O(1).
pub fn surrogate_pair_to_code_point(hi: UInt16, lo: UInt16) -> Int {
  var h = hi as Int;
  var l = lo as Int;
  if h < 0xD800 || h > 0xDBFF {
    return -1;
  }
  if l < 0xDC00 || l > 0xDFFF {
    return -1;
  }
  return 0x10000 + ((h - 0xD800) << 10) + (l - 0xDC00);
}

// Collect the Unicode code points of a string (valid UTF-8 by construction).
fn _collect_cps(s: Str) -> Vec[Int] {
  var result = Vec[Int].new();
  var i: Int = 0;
  var len = s.len();
  while i < len {
    var b0 = s.byte_at(i) as Int;
    b0 = b0 & 0xFF;
    if b0 <= 0x7F {
      result.push(b0);
      i = i + 1;
    } elif (b0 & 0xE0) == 0xC0 {
      var b1 = s.byte_at(i + 1) as Int;
    b1 = b1 & 0xFF;
      var cp = ((b0 & 0x1F) << 6) | (b1 & 0x3F);
      result.push(cp);
      i = i + 2;
    } elif (b0 & 0xF0) == 0xE0 {
      var b1 = s.byte_at(i + 1) as Int;
    b1 = b1 & 0xFF;
      var b2 = s.byte_at(i + 2) as Int;
    b2 = b2 & 0xFF;
      var cp2 = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
      result.push(cp2);
      i = i + 3;
    } else {
      var b1 = s.byte_at(i + 1) as Int;
    b1 = b1 & 0xFF;
      var b2 = s.byte_at(i + 2) as Int;
    b2 = b2 & 0xFF;
      var b3 = s.byte_at(i + 3) as Int;
    b3 = b3 & 0xFF;
      var cp3 = ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
      result.push(cp3);
      i = i + 4;
    }
  }
  return result;
}

// Render a vector of code points as a UTF-8 string.
fn _cps_to_str(cps: &Vec[Int]) -> Str {
  var buf = Vec[UInt8].new();
  var i: Int = 0;
  while i < cps.len() {
    _push_utf8(&buf, cps[i]);
    i = i + 1;
  }
  if buf.len() == 0 {
    return "";
  }
  return Str::from_utf8(buf);
}

// Append the UTF-8 encoding of a code point to a byte vector.
fn _push_utf8(out: &mut Vec[UInt8], cp: Int) {
  if cp <= 0x7F {
    out.push(cp as UInt8);
  } elif cp <= 0x7FF {
    out.push((0xC0 | (cp >> 6)) as UInt8);
    out.push((0x80 | (cp & 0x3F)) as UInt8);
  } elif cp <= 0xFFFF {
    out.push((0xE0 | (cp >> 12)) as UInt8);
    out.push((0x80 | ((cp >> 6) & 0x3F)) as UInt8);
    out.push((0x80 | (cp & 0x3F)) as UInt8);
  } else {
    out.push((0xF0 | (cp >> 18)) as UInt8);
    out.push((0x80 | ((cp >> 12) & 0x3F)) as UInt8);
    out.push((0x80 | ((cp >> 6) & 0x3F)) as UInt8);
    out.push((0x80 | (cp & 0x3F)) as UInt8);
  }
}




