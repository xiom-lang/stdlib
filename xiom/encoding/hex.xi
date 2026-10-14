// XIOM - Encoding: Hex
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.encoding.hex

// Depends on: xiom.string

// ============================================================================
// Hexadecimal encoding and decoding for bytes, strings, and integers.
// Implemented locally (same-name delegation to xiom.encoding crashes the
// compiler -- see xiom.convert.base58 for the probe reference).
// ============================================================================

use xiom.string;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

// Raw byte read at `i` (wave 138): the function-shaped cached-pointer read
// (the wave-136 pattern -- an inline `unsafe { }` VALUE expression misbehaved
// on the pin). Complexity: O(1).
fn _hex_raw_byte(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

// Runtime-`xiom_char_at`-equivalent UTF-8 decode over a cached (base, len)
// view (copied from the wave-136 xiom.encoding helper; xiom_char_at strnlens
// per call, so the per-position codec loops were quadratic). Complexity: O(1).
fn _hex_char_at_runtime(base: *UInt8, len: Int, pos: Int) -> Char {
  if pos < 0 || pos >= len {
    return to_char(0);
  }
  var b0 = (_hex_raw_byte(base, pos) as Int) & 0xFF;
  if b0 < 0x80 {
    return to_char(b0);
  }
  var n = 0;
  var cp = 0;
  if (b0 & 0xE0) == 0xC0 {
    n = 2;
    cp = b0 & 0x1F;
  } elif (b0 & 0xF0) == 0xE0 {
    n = 3;
    cp = b0 & 0x0F;
  } elif (b0 & 0xF8) == 0xF0 {
    n = 4;
    cp = b0 & 0x07;
  } else {
    return to_char(b0);
  }
  var i = 1;
  while i < n {
    var cb = 0;
    if pos + i < len {
      cb = (_hex_raw_byte(base, pos + i) as Int) & 0xFF;
    }
    if (cb & 0xC0) != 0x80 {
      return to_char(b0);
    }
    cp = (cp << 6) | (cb & 0x3F);
    i = i + 1;
  }
  return to_char(cp);
}

/// Numeric value of a hex digit character (0-9, a-f, A-F); -1 otherwise.
fn _hex_value(c: UInt8) -> Int {
  var code = c as Int;
  code = code & 0xFF;
  if code >= 48 && code <= 57 { return code - 48; }
  if code >= 97 && code <= 102 { return code - 87; }
  if code >= 65 && code <= 70 { return code - 55; }
  -1
}

/// Lowercase hex character for a nibble value (0-15).
fn _hex_nibble_lower(n: Int) -> UInt8 {
  if n < 10 { return (48 + n) as UInt8; }
  (87 + n) as UInt8
}

/// Uppercase hex character for a nibble value (0-15).
fn _hex_nibble_upper(n: Int) -> UInt8 {
  if n < 10 { return (48 + n) as UInt8; }
  (55 + n) as UInt8
}

/// Encodes a byte vector as a lowercase hexadecimal string (two digits per
/// byte). Empty input yields "". Complexity: O(n).
pub fn hex_encode(data: &Vec[UInt8]) -> Str
  ensures: result.len() == data.len() * 2
{
  let len = data.len();
  let out_len = len * 2;
  unsafe {
    var buf = malloc(out_len + 1);
    var i = 0;
    while i < len {
      var b = data[i] as Int;
      b = b & 0xFF;
      buf[i * 2] = _hex_nibble_lower(b >> 4);
      buf[i * 2 + 1] = _hex_nibble_lower(b & 15);
      i = i + 1;
    };
    buf[out_len] = 0;
    return Str.from_cstring(buf);
  }
}

/// Decodes a hexadecimal string into bytes. Accepts both digit cases. Returns
/// Err on an odd length or an invalid hex character. Complexity: O(n).
pub fn hex_decode(s: Str) -> Result[Vec[UInt8], Str]
  ensures: (s.len() % 2 != 0) => (result.is_err)
  ensures: result is Ok => result.len() == s.len() / 2
{
  let len = s.len();
  if len % 2 != 0 {
    return Err("hex string must have even length");
  };
  var result = Vec[UInt8].new();
  let base = s.c_str();
  var i = 0;
  while i < len {
    var hi = _hex_value(_hex_raw_byte(base, i));
    var lo = _hex_value(_hex_raw_byte(base, i + 1));
    if hi < 0 || lo < 0 {
      return Err("invalid hex character");
    };
    result.push(((hi << 4) | lo) as UInt8);
    i = i + 2;
  };
  Ok(result)
}

/// Encodes a byte vector as an uppercase hexadecimal string.
/// Complexity: O(n).
pub fn hex_encode_upper(data: &Vec[UInt8]) -> Str
  ensures: result.len() == data.len() * 2
{
  let len = data.len();
  let out_len = len * 2;
  unsafe {
    var buf = malloc(out_len + 1);
    var i = 0;
    while i < len {
      var b = data[i] as Int;
      b = b & 0xFF;
      buf[i * 2] = _hex_nibble_upper(b >> 4);
      buf[i * 2 + 1] = _hex_nibble_upper(b & 15);
      i = i + 1;
    };
    buf[out_len] = 0;
    return Str.from_cstring(buf);
  }
}

/// Encodes the UTF-8 bytes of a string as lowercase hex. Complexity: O(n).
pub fn hex_encode_str(s: Str) -> Str
  ensures: (s.len() == 0) => (result.len() == 0)
  ensures: result.len() % 2 == 0
{
  var bytes = Vec[UInt8].new();
  var i = 0;
  let slen = s.len();
  let base = s.c_str();
  while i < slen {
    var c = _hex_char_at_runtime(base, slen, i);
    xiom.char.encode_utf8(c, &bytes);
    i = i + xiom.char.len_utf8(c);
  };
  hex_encode(&bytes)
}

/// Decodes a hex string back into a string (decoded bytes copied verbatim;
/// callers are responsible for UTF-8 validity). Returns Err on invalid hex.
/// Complexity: O(n).
pub fn hex_decode_str(s: Str) -> Result[Str, Str]
  ensures: (s.len() % 2 != 0) => (result.is_err)
  ensures: result is Ok => result.len() <= s.len() / 2
{
  var r = hex_decode(s);
  match r {
    Ok(bytes) => {
      let blen = bytes.len();
      if blen == 0 {
        return Ok("");
      };
      unsafe {
        var buf = malloc(blen + 1);
        var i = 0;
        while i < blen {
          buf[i] = bytes[i];
          i = i + 1;
        };
        buf[blen] = 0;
        return Ok(Str.from_cstring(buf));
      }
    },
    Err(e) => {
      return Err(e);
    },
  }
}

/// Encodes an integer as a lowercase hex string (no sign, no prefix; 0 -> "0").
/// Complexity: O(log16(n)).
pub fn hex_encode_int(n: Int) -> Str
  ensures: (n == 0) => (result.len() == 1)
  ensures: result.len() <= 16
  ensures: (n > 0) => (result.len() >= 1)
  ensures: (n < 0 && 0 - n > 0) => (result.len() >= 1)
{
  if n == 0 {
    return "0";
  };
  var digits: [16]UInt8;
  var pos: Int = 16;
  var val: Int = n;
  if val < 0 {
    val = -val;
  };
  while val > 0 {
    pos = pos - 1;
    var d = val & 15;
    digits[pos] = _hex_nibble_lower(d);
    val = val >> 4;
  };
  let out_len = 16 - pos;
  unsafe {
    var buf = malloc(out_len + 1);
    var i = 0;
    while i < out_len {
      buf[i] = digits[pos + i];
      i = i + 1;
    };
    buf[out_len] = 0;
    return Str.from_cstring(buf);
  }
}

/// Parses a hex string into an integer. Returns Err on an empty string or an
/// invalid hex character. Complexity: O(n).
pub fn hex_decode_int(s: Str) -> Result[Int, Str]
  ensures: (s.len() == 0) => (result.is_err)
  ensures: result is Ok => s.len() > 0
{
  let len = s.len();
  if len == 0 {
    return Err("empty hex string");
  };
  var result: Int = 0;
  let base = s.c_str();
  var i = 0;
  while i < len {
    var v = _hex_value(_hex_raw_byte(base, i));
    if v < 0 {
      return Err("invalid hex character");
    };
    result = (result << 4) | v;
    i = i + 1;
  };
  Ok(result)
}

/// The numeric value of a hex digit character (0-15), or None if `c` is not a
/// hex digit. Complexity: O(1).
pub fn hex_nibble_to_int(c: Char) -> Option[Int]
  ensures: (c == '\0') => (result.is_none)
{
  var code = to_int_from_char(c);
  if code >= 48 && code <= 57 { return Some(code - 48); }
  if code >= 97 && code <= 102 { return Some(code - 87); }
  if code >= 65 && code <= 70 { return Some(code - 55); }
  None
}

/// The hex digit character for a 0-15 value (lowercase). Returns '\0' for a
/// value outside that range. Complexity: O(1).
pub fn hex_int_to_nibble(n: Int) -> Char
  ensures: (n < 0 || n > 15) => (result == '\0')
  ensures: (n >= 0 && n <= 15) => (result != '\0')
{
  if n < 0 || n > 15 {
    return '\0';
  };
  to_char(_hex_nibble_lower(n) as Int)
}
