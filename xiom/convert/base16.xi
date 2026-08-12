// XIOM - Conversion: Base16
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.base16

// Depends on: none

// ============================================================================
// Hexadecimal (base16) encoding/decoding. Canonical implementations of the
// lowercase hex codec (RFC 4648 §8). Hex is the byte-oriented radix-16 codec;
// for integer <-> string radix conversion see xiom.num.base.
// ============================================================================

use xiom.string;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

/// Numeric value of a hex byte (0-9, a-f, A-F); -1 for any other byte.
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

/// Encodes bytes as a lowercase hexadecimal string (two hex digits per byte).
/// Empty input yields "". Complexity: O(n), n = data length.
pub fn hex_encode(data: &Vec[UInt8]) -> Str {
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

/// Decodes a hexadecimal string back into bytes. Accepts both digit cases.
/// Returns Err on an odd length or an invalid hex character.
/// Complexity: O(n), n = string length.
pub fn hex_decode(s: Str) -> Result[Vec[UInt8], Str] {
  let len = s.len();
  if len % 2 != 0 {
    return Err("hex string must have even length");
  };
  var result = Vec[UInt8].new();
  var i = 0;
  while i < len {
    var hi = _hex_value(string.byte_at(s, i));
    var lo = _hex_value(string.byte_at(s, i + 1));
    if hi < 0 || lo < 0 {
      return Err("invalid hex character");
    };
    result.push(((hi << 4) | lo) as UInt8);
    i = i + 2;
  };
  Ok(result)
}

/// Encodes a string's UTF-8 bytes as a lowercase hex string.
/// Complexity: O(n), n = string byte length.
pub fn hex_encode_str(s: Str) -> Str {
  var bytes = Vec[UInt8].new();
  var i = 0;
  let slen = s.len();
  while i < slen {
    var c = s.char_at(i);
    xiom.char.encode_utf8(c, &bytes);
    i = i + xiom.char.len_utf8(c);
  };
  hex_encode(&bytes)
}

/// Decodes a hex string into a UTF-8 string. The decoded bytes are copied
/// verbatim; callers are responsible for UTF-8 validity of their hex input
/// (the string module's validation helpers can be used for strict checking).
/// Complexity: O(n), n = string length.
pub fn hex_decode_str(s: Str) -> Result[Str, Str] {
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
