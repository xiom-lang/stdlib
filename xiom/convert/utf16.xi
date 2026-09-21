// XIOM - Conversion: Utf16
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.utf16

// Depends on: none

// ============================================================================
// UTF-16 encoding/decoding and byte serialization. Strings are valid UTF-8 by
// construction, so code points are collected with a local byte decoder (byte_at
// byte offsets); byte serialization prepends a BOM (0xFEFF) and the decoders
// skip a leading BOM. Invalid input yields Err, never a crash.
// ============================================================================

use xiom.string;
use xiom.char;

/// Encode a string as UTF-16 code units (native order, no BOM).
/// Parameters: s -- the input string.
/// Returns: one UTF-16 code unit per BMP code point, surrogate pairs for
///          supplementary characters.
/// Complexity: O(n), n = code points.
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

/// Decode UTF-16 code units to a string.
/// Parameters: bytes -- the code units (a leading BOM is skipped).
/// Returns: Ok(Str) on success; Err for a lone surrogate, an invalid code
///          unit range, or an overlong result.
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

/// Encode a string as UTF-16LE bytes, including a BOM.
/// Parameters: s -- the input string.
/// Returns: the little-endian byte sequence.
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

/// Encode a string as UTF-16BE bytes, including a BOM.
/// Parameters: s -- the input string.
/// Returns: the big-endian byte sequence.
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





