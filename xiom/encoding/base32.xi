// XIOM - Encoding: Base32
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.encoding.base32

// Depends on: xiom.string

// ============================================================================
// RFC-4648 Base32 and Base32hex encoding and decoding.
// Implemented locally (same-name delegation to xiom.encoding crashes the
// compiler -- see xiom.convert.base58 for the probe reference).
// ============================================================================

use xiom.string;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

const _B32_ALPHABET: Str = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
const _B32HEX_ALPHABET: Str = "0123456789ABCDEFGHIJKLMNOPQRSTUV";

/// Decode value of a base32 character byte; -1 for an invalid character.
/// `hex_alpha` selects the base32hex alphabet.
fn _b32_index(code: Int, hex_alpha: Bool) -> Int {
  if hex_alpha {
    if code >= 48 && code <= 57 { return code - 48; }
    if code >= 65 && code <= 86 { return code - 55; }
    if code >= 97 && code <= 118 { return code - 87; }
    return -1;
  };
  if code >= 65 && code <= 90 { return code - 65; }
  if code >= 50 && code <= 55 { return code - 24; }
  -1
}

/// Shared encoder: bytes -> base32 string with '=' padding (RFC 4648).
fn _b32_encode(data: &Vec[UInt8], alphabet: Str) -> Str {
  let len = data.len();
  let out_len = ((len + 4) / 5) * 8;
  unsafe {
    var buf = malloc(out_len + 1);
    var i: Int = 0;
    var out: Int = 0;
    while i + 4 < len {
      var b0 = data[i] as Int;
      var b1 = data[i + 1] as Int;
      var b2 = data[i + 2] as Int;
      var b3 = data[i + 3] as Int;
      var b4 = data[i + 4] as Int;
      b0 = b0 & 0xFF;
      b1 = b1 & 0xFF;
      b2 = b2 & 0xFF;
      b3 = b3 & 0xFF;
      b4 = b4 & 0xFF;
      buf[out]     = xiom_char_at(alphabet, (b0 >> 3) & 31) as UInt8;
      buf[out + 1] = xiom_char_at(alphabet, ((b0 << 2) | (b1 >> 6)) & 31) as UInt8;
      buf[out + 2] = xiom_char_at(alphabet, (b1 >> 1) & 31) as UInt8;
      buf[out + 3] = xiom_char_at(alphabet, ((b1 << 4) | (b2 >> 4)) & 31) as UInt8;
      buf[out + 4] = xiom_char_at(alphabet, ((b2 << 1) | (b3 >> 7)) & 31) as UInt8;
      buf[out + 5] = xiom_char_at(alphabet, (b3 >> 2) & 31) as UInt8;
      buf[out + 6] = xiom_char_at(alphabet, ((b3 << 3) | (b4 >> 5)) & 31) as UInt8;
      buf[out + 7] = xiom_char_at(alphabet, b4 & 31) as UInt8;
      out = out + 8;
      i = i + 5;
    };
    let rem = len - i;
    if rem == 1 {
      var b0 = data[i] as Int;
      b0 = b0 & 0xFF;
      buf[out]     = xiom_char_at(alphabet, (b0 >> 3) & 31) as UInt8;
      buf[out + 1] = xiom_char_at(alphabet, (b0 << 2) & 31) as UInt8;
      buf[out + 2] = 61;
      buf[out + 3] = 61;
      buf[out + 4] = 61;
      buf[out + 5] = 61;
      buf[out + 6] = 61;
      buf[out + 7] = 61;
      out = out + 8;
    } elif rem == 2 {
      var b0 = data[i] as Int;
      var b1 = data[i + 1] as Int;
      b0 = b0 & 0xFF;
      b1 = b1 & 0xFF;
      buf[out]     = xiom_char_at(alphabet, (b0 >> 3) & 31) as UInt8;
      buf[out + 1] = xiom_char_at(alphabet, ((b0 << 2) | (b1 >> 6)) & 31) as UInt8;
      buf[out + 2] = xiom_char_at(alphabet, (b1 >> 1) & 31) as UInt8;
      buf[out + 3] = xiom_char_at(alphabet, (b1 << 4) & 31) as UInt8;
      buf[out + 4] = 61;
      buf[out + 5] = 61;
      buf[out + 6] = 61;
      buf[out + 7] = 61;
      out = out + 8;
    } elif rem == 3 {
      var b0 = data[i] as Int;
      var b1 = data[i + 1] as Int;
      var b2 = data[i + 2] as Int;
      b0 = b0 & 0xFF;
      b1 = b1 & 0xFF;
      b2 = b2 & 0xFF;
      buf[out]     = xiom_char_at(alphabet, (b0 >> 3) & 31) as UInt8;
      buf[out + 1] = xiom_char_at(alphabet, ((b0 << 2) | (b1 >> 6)) & 31) as UInt8;
      buf[out + 2] = xiom_char_at(alphabet, (b1 >> 1) & 31) as UInt8;
      buf[out + 3] = xiom_char_at(alphabet, ((b1 << 4) | (b2 >> 4)) & 31) as UInt8;
      buf[out + 4] = xiom_char_at(alphabet, (b2 << 1) & 31) as UInt8;
      buf[out + 5] = 61;
      buf[out + 6] = 61;
      buf[out + 7] = 61;
      out = out + 8;
    } elif rem == 4 {
      var b0 = data[i] as Int;
      var b1 = data[i + 1] as Int;
      var b2 = data[i + 2] as Int;
      var b3 = data[i + 3] as Int;
      b0 = b0 & 0xFF;
      b1 = b1 & 0xFF;
      b2 = b2 & 0xFF;
      b3 = b3 & 0xFF;
      buf[out]     = xiom_char_at(alphabet, (b0 >> 3) & 31) as UInt8;
      buf[out + 1] = xiom_char_at(alphabet, ((b0 << 2) | (b1 >> 6)) & 31) as UInt8;
      buf[out + 2] = xiom_char_at(alphabet, (b1 >> 1) & 31) as UInt8;
      buf[out + 3] = xiom_char_at(alphabet, ((b1 << 4) | (b2 >> 4)) & 31) as UInt8;
      buf[out + 4] = xiom_char_at(alphabet, ((b2 << 1) | (b3 >> 7)) & 31) as UInt8;
      buf[out + 5] = xiom_char_at(alphabet, (b3 >> 2) & 31) as UInt8;
      buf[out + 6] = xiom_char_at(alphabet, (b3 << 3) & 31) as UInt8;
      buf[out + 7] = 61;
      out = out + 8;
    };
    buf[out_len] = 0;
    return Str.from_cstring(buf);
  }
}

/// Shared decoder: base32/base32hex string -> bytes. Accepts both digit cases
/// and optional '=' padding. Errors on invalid characters, misplaced padding,
/// or an unpadded length that cannot map to a whole number of bytes.
fn _b32_decode(s: Str, hex_alpha: Bool) -> Result[Vec[UInt8], Str] {
  var result = Vec[UInt8].new();
  let len = s.len();
  if len == 0 { return Ok(result); };
  var data_len = len;
  while data_len > 0 {
    var bc = string.byte_at(s, data_len - 1) as Int;
    bc = bc & 0xFF;
    if bc == 61 {
      data_len = data_len - 1;
    } else {
      break;
    };
  };
  var rem = data_len % 8;
  if rem == 1 || rem == 3 || rem == 6 {
    return Err("invalid base32 length");
  };
  var bits: Int = 0;
  var bit_count: Int = 0;
  var i: Int = 0;
  while i < data_len {
    var bc = string.byte_at(s, i) as Int;
    bc = bc & 0xFF;
    if bc == 61 {
      return Err("invalid base32 padding position");
    };
    var v = _b32_index(bc, hex_alpha);
    if v < 0 { return Err("invalid base32 character"); };
    bits = (bits << 5) | v;
    bit_count = bit_count + 5;
    if bit_count >= 8 {
      bit_count = bit_count - 8;
      var shifted = bits >> bit_count;
      var byte = shifted & 0xFF;
      result.push(byte as UInt8);
      var one = 1;
      var mask = (one << bit_count) - 1;
      bits = bits & mask;
    };
    i = i + 1;
  };
  Ok(result)
}

/// Encodes bytes as an RFC 4648 base32 string (alphabet A-Z, 2-7), padded
/// with '=' to a multiple of 8 characters. Complexity: O(n).
pub fn base32_encode(data: &Vec[UInt8]) -> Str {
  _b32_encode(data, _B32_ALPHABET)
}

/// Decodes an RFC 4648 base32 string to bytes. Returns Err on invalid input.
/// Complexity: O(n).
pub fn base32_decode(s: Str) -> Result[Vec[UInt8], Str] {
  _b32_decode(s, false)
}

/// Encodes bytes as a base32hex string (RFC 4648 section 7, alphabet 0-9, A-V),
/// padded with '='. Complexity: O(n).
pub fn base32hex_encode(data: &Vec[UInt8]) -> Str {
  _b32_encode(data, _B32HEX_ALPHABET)
}

/// Decodes a base32hex string to bytes (both digit cases accepted). Returns
/// Err on invalid input. Complexity: O(n).
pub fn base32hex_decode(s: Str) -> Result[Vec[UInt8], Str] {
  _b32_decode(s, true)
}

/// Encodes a string's UTF-8 bytes as base32. Complexity: O(n).
pub fn base32_encode_str(s: Str) -> Str {
  var bytes = Vec[UInt8].new();
  var i = 0;
  let slen = s.len();
  while i < slen {
    var c = s.char_at(i);
    xiom.char.encode_utf8(c, &bytes);
    i = i + xiom.char.len_utf8(c);
  };
  base32_encode(&bytes)
}

/// Decodes base32 into a UTF-8 string (bytes copied verbatim; callers are
/// responsible for UTF-8 validity). Returns Err on invalid base32.
/// Complexity: O(n).
pub fn base32_decode_str(s: Str) -> Result[Str, Str] {
  var r = base32_decode(s);
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
