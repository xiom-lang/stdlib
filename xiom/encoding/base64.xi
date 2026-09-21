// XIOM - Encoding: Base64
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.encoding.base64

// Depends on: xiom.string

// ============================================================================
// Base64 and base64url encoding and decoding with padding variants.
// Implemented locally (same-name delegation to xiom.encoding crashes the
// compiler -- see xiom.convert.base58 for the probe reference).
// ============================================================================

use xiom.string;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

const _B64_ALPHABET: Str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
const _B64U_ALPHABET: Str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

/// Decode value of a base64 character byte; -1 for an invalid character.
fn _b64_index(c: UInt8) -> Int {
  var code = c as Int;
  code = code & 0xFF;
  if code >= 65 && code <= 90 { return code - 65; }
  if code >= 97 && code <= 122 { return code - 71; }
  if code >= 48 && code <= 57 { return code + 4; }
  if code == 43 { return 62; }
  if code == 47 { return 63; }
  -1
}

/// Decode value of a base64url character byte; -1 for an invalid character.
fn _b64u_index(c: UInt8) -> Int {
  var code = c as Int;
  code = code & 0xFF;
  if code >= 65 && code <= 90 { return code - 65; }
  if code >= 97 && code <= 122 { return code - 71; }
  if code >= 48 && code <= 57 { return code + 4; }
  if code == 45 { return 62; }
  if code == 95 { return 63; }
  -1
}

/// Writes one 4-character base64 group for the triplet (b0,b1,b2).
/// `pad1`/`pad2` select the padding layout for a 1- or 2-byte tail.
fn _b64_write_group(buf: *UInt8, dst_idx: Int, b0: UInt8, b1: UInt8, b2: UInt8, pad1: Bool, pad2: Bool)
  requires: dst_idx >= 0
{
  let i0 = b0 as Int;
  let i1 = b1 as Int;
  let i2 = b2 as Int;
  unsafe {
    buf[dst_idx]     = xiom_char_at(_B64_ALPHABET, (i0 >> 2) & 63) as UInt8;
    buf[dst_idx + 1] = xiom_char_at(_B64_ALPHABET, ((i0 << 4) | (i1 >> 4)) & 63) as UInt8;
    if pad1 {
      buf[dst_idx + 2] = 61;
      buf[dst_idx + 3] = 61;
    } elif pad2 {
      buf[dst_idx + 2] = xiom_char_at(_B64_ALPHABET, ((i1 << 2) | (i2 >> 6)) & 63) as UInt8;
      buf[dst_idx + 3] = 61;
    } else {
      buf[dst_idx + 2] = xiom_char_at(_B64_ALPHABET, ((i1 << 2) | (i2 >> 6)) & 63) as UInt8;
      buf[dst_idx + 3] = xiom_char_at(_B64_ALPHABET, i2 & 63) as UInt8;
    };
  };
}

/// Writes the URL-safe base64 group for (b0,b1,b2); `has_one`/`has_two` select
/// the output width (2, 3 or 4 characters, never padded).
fn _b64u_write_group(buf: *UInt8, dst_idx: Int, b0: UInt8, b1: UInt8, b2: UInt8, has_one: Bool, has_two: Bool)
  requires: dst_idx >= 0
{
  let i0 = b0 as Int;
  let i1 = b1 as Int;
  let i2 = b2 as Int;
  unsafe {
    buf[dst_idx]     = xiom_char_at(_B64U_ALPHABET, (i0 >> 2) & 63) as UInt8;
    buf[dst_idx + 1] = xiom_char_at(_B64U_ALPHABET, ((i0 << 4) | (i1 >> 4)) & 63) as UInt8;
    if !has_one {
      return;
    };
    buf[dst_idx + 2] = xiom_char_at(_B64U_ALPHABET, ((i1 << 2) | (i2 >> 6)) & 63) as UInt8;
    if !has_two {
      return;
    };
    buf[dst_idx + 3] = xiom_char_at(_B64U_ALPHABET, i2 & 63) as UInt8;
  };
}

/// Encodes bytes as a standard base64 string with mandatory '=' padding.
/// Empty input yields "". Complexity: O(n).
pub fn base64_encode(data: &Vec[UInt8]) -> Str {
  let len = data.len();
  let out_len = ((len + 2) / 3) * 4;
  unsafe {
    var buf = malloc(out_len + 1);
    var i: Int = 0;
    var out: Int = 0;
    while i + 2 < len {
      _b64_write_group(buf, out, data[i], data[i + 1], data[i + 2], false, false);
      out = out + 4;
      i = i + 3;
    };
    if i < len {
      var b0 = data[i];
      var b1: UInt8 = 0;
      var b2: UInt8 = 0;
      var pad1 = false;
      var pad2 = false;
      if i + 1 < len {
        b1 = data[i + 1];
        pad2 = true;
      } else {
        pad1 = true;
      };
      _b64_write_group(buf, out, b0, b1, b2, pad1, pad2);
      out = out + 4;
    };
    buf[out_len] = 0;
    return Str.from_cstring(buf);
  }
}

/// Decodes a standard base64 string to bytes. Accepts optional '=' padding.
/// Returns Err on a non-multiple-of-4 length or an invalid character.
/// Complexity: O(n).
pub fn base64_decode(s: Str) -> Result[Vec[UInt8], Str] {
  var result = Vec[UInt8].new();
  let len = s.len();
  if len % 4 != 0 {
    return Err("base64 length must be a multiple of 4");
  };
  var i: Int = 0;
  var pad: Int = 0;
  while i < len {
    var c = s.char_at(i);
    if c != '=' {
      i = i + 1;
    } else {
      break;
    };
  };
  while i < len {
    var c = s.char_at(i);
    if c == '=' {
      pad = pad + 1;
      i = i + 1;
    } else {
      break;
    };
  };
  while i < len {
    var c = s.char_at(i);
    if c != '=' {
      return Err("invalid base64 padding");
    };
    i = i + 1;
  };
  let data_len = len - pad;
  i = 0;
  while i + 3 < data_len {
    var v0 = _b64_index(string.byte_at(s, i));
    var v1 = _b64_index(string.byte_at(s, i + 1));
    var v2 = _b64_index(string.byte_at(s, i + 2));
    var v3 = _b64_index(string.byte_at(s, i + 3));
    if v0 < 0 || v1 < 0 || v2 < 0 || v3 < 0 {
      return Err("invalid base64 character");
    };
    result.push(((v0 << 2) | (v1 >> 4)) as UInt8);
    result.push(((v1 << 4) | (v2 >> 2)) as UInt8);
    result.push(((v2 << 6) | v3) as UInt8);
    i = i + 4;
  };
  if i < data_len {
    var v0 = _b64_index(string.byte_at(s, i));
    var v1 = _b64_index(string.byte_at(s, i + 1));
    if v0 < 0 || v1 < 0 {
      return Err("invalid base64 character");
    };
    result.push(((v0 << 2) | (v1 >> 4)) as UInt8);
    if pad < 2 {
      var v2 = _b64_index(string.byte_at(s, i + 2));
      if v2 < 0 {
        return Err("invalid base64 character");
      };
      result.push(((v1 << 4) | (v2 >> 2)) as UInt8);
      if pad == 0 {
        var v3 = _b64_index(string.byte_at(s, i + 3));
        if v3 < 0 {
          return Err("invalid base64 character");
        };
        result.push(((v2 << 6) | v3) as UInt8);
      };
    };
  };
  Ok(result)
}

/// Encodes a string's UTF-8 bytes as standard base64. Complexity: O(n).
pub fn base64_encode_str(s: Str) -> Str {
  var bytes = Vec[UInt8].new();
  var i = 0;
  let slen = s.len();
  while i < slen {
    var c = s.char_at(i);
    xiom.char.encode_utf8(c, &bytes);
    i = i + xiom.char.len_utf8(c);
  };
  base64_encode(&bytes)
}

/// Decodes base64 into a UTF-8 string (bytes copied verbatim; callers are
/// responsible for UTF-8 validity). Returns Err on invalid base64.
/// Complexity: O(n).
pub fn base64_decode_str(s: Str) -> Result[Str, Str] {
  var r = base64_decode(s);
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

/// Encodes bytes as base64 with mandatory padding. Standard base64 always
/// pads, so this is equivalent to base64_encode. Complexity: O(n).
pub fn base64_encode_padded(data: &Vec[UInt8]) -> Str {
  base64_encode(data)
}

/// Decodes a base64 string that MUST carry correct padding: the string length
/// must be a multiple of 4 and the number of trailing '=' characters must
/// match the data length (0, 1 or 2 for full, 2- and 1-byte tails). Returns
/// Err on malformed padding or an invalid character. Complexity: O(n).
pub fn base64_decode_padded(s: Str) -> Result[Vec[UInt8], Str] {
  let len = s.len();
  if len % 4 != 0 {
    return Err("base64 length must be a multiple of 4");
  };
  var pad: Int = 0;
  var i: Int = len;
  while i > 0 {
    var c = s.char_at(i - 1);
    if c == '=' {
      pad = pad + 1;
      i = i - 1;
    } else {
      break;
    };
  };
  if pad > 2 {
    return Err("invalid base64 padding");
  };
  let data_len = len - pad;
  if data_len == 0 {
    return Err("base64 string contains no data");
  };
  var m = data_len % 4;
  var need = 0;
  if m == 2 {
    need = 2;
  } elif m == 3 {
    need = 1;
  } elif m == 1 {
    return Err("invalid base64 padding");
  };
  if pad != need {
    return Err("invalid base64 padding length");
  };
  base64_decode(s)
}

/// Encodes bytes as an unpadded URL-safe base64 string (alphabet A-Za-z0-9-_).
/// Empty input yields "". Complexity: O(n).
pub fn base64url_encode(data: &Vec[UInt8]) -> Str {
  let len = data.len();
  let out_len = ((len + 2) / 3) * 4;
  var actual_len = out_len;
  let rem = len % 3;
  if rem == 1 { actual_len = out_len - 2; };
  if rem == 2 { actual_len = out_len - 1; };
  unsafe {
    var buf = malloc(actual_len + 1);
    var i: Int = 0;
    var out: Int = 0;
    while i + 2 < len {
      _b64u_write_group(buf, out, data[i], data[i + 1], data[i + 2], true, true);
      out = out + 4;
      i = i + 3;
    };
    if i < len {
      var b0 = data[i];
      var b1: UInt8 = 0;
      var b2: UInt8 = 0;
      var has_one = i + 1 < len;
      var has_two = i + 2 < len;
      if has_one {
        b1 = data[i + 1];
      };
      if has_two {
        b2 = data[i + 2];
      };
      _b64u_write_group(buf, out, b0, b1, b2, has_one, has_two);
      // Partial groups emit fewer than 4 chars; advancing by 4 left the NUL
      // terminator one byte PAST the malloc'd buffer (heap overflow) and let
      // an uninitialized byte leak into the string.
      if has_two {
        out = out + 4;
      } else {
        if has_one {
          out = out + 3;
        } else {
          out = out + 2;
        };
      };
    };
    buf[out] = 0;
    return Str.from_cstring(buf);
  }
}

/// Decodes an unpadded URL-safe base64 string to bytes. Optional '=' padding
/// is tolerated. Returns Err on an invalid character. Complexity: O(n).
pub fn base64url_decode(s: Str) -> Result[Vec[UInt8], Str] {
  var result = Vec[UInt8].new();
  let len = s.len();
  var i: Int = 0;
  while i + 3 < len {
    var v0 = _b64u_index(string.byte_at(s, i));
    var v1 = _b64u_index(string.byte_at(s, i + 1));
    var v2 = _b64u_index(string.byte_at(s, i + 2));
    var v3 = _b64u_index(string.byte_at(s, i + 3));
    if v0 < 0 || v1 < 0 || v2 < 0 || v3 < 0 {
      return Err("invalid base64url character");
    };
    result.push(((v0 << 2) | (v1 >> 4)) as UInt8);
    result.push(((v1 << 4) | (v2 >> 2)) as UInt8);
    result.push(((v2 << 6) | v3) as UInt8);
    i = i + 4;
  };
  if i + 1 < len {
    var v0 = _b64u_index(string.byte_at(s, i));
    var v1 = _b64u_index(string.byte_at(s, i + 1));
    if v0 < 0 || v1 < 0 {
      return Err("invalid base64url character");
    };
    result.push(((v0 << 2) | (v1 >> 4)) as UInt8);
    if i + 2 < len {
      var v2 = _b64u_index(string.byte_at(s, i + 2));
      if v2 < 0 {
        return Err("invalid base64url character");
      };
      result.push(((v1 << 4) | (v2 >> 2)) as UInt8);
      if i + 3 < len {
        var v3 = _b64u_index(string.byte_at(s, i + 3));
        if v3 < 0 {
          return Err("invalid base64url character");
        };
        result.push(((v2 << 6) | v3) as UInt8);
      };
    };
  };
  Ok(result)
}
