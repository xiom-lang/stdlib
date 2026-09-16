// XIOM - Conversion: Utf32
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.convert.utf32

// Depends on: none

// ============================================================================
// UTF-32 encoding/decoding and byte serialization. Strings are valid UTF-8 by
// construction, so code points are collected with a local byte decoder (byte_at
// byte offsets); byte serialization prepends a BOM (0xFEFF) and the decoders
// skip a leading BOM. Invalid input yields Err, never a crash.
// ============================================================================

use xiom.string;
use xiom.char;

/// Encode a string as UTF-32 code points (no BOM).
/// Parameters: s -- the input string.
/// Returns: one UInt32 per Unicode code point.
/// Complexity: O(n), n = code points.
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
/// Parameters: code_points -- the code points (a leading BOM is skipped).
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

/// Encode a string as UTF-32LE bytes, including a BOM.
/// Parameters: s -- the input string.
/// Returns: the little-endian byte sequence.
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

/// Encode a string as UTF-32BE bytes, including a BOM.
/// Parameters: s -- the input string.
/// Returns: the big-endian byte sequence.
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





