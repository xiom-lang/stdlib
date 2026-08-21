// XIOM - Conversion: Base64Url
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.base64url

// Depends on: none

// ============================================================================
// URL-safe base64 encoding/decoding (RFC 4648 S5, alphabet A-Za-z0-9-_,
// unpadded). Implemented locally (same-name delegation to xiom.encoding
// crashes the compiler -- see xiom.convert.base58 for the probe reference).
// ============================================================================

use xiom.string;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

const _B64U_ALPHABET: Str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

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

/// Encodes bytes as an unpadded URL-safe base64 string.
/// Empty input yields "". Complexity: O(n), n = data length.
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
      var b0 = data[i] as Int;
      var b1 = data[i + 1] as Int;
      var b2 = data[i + 2] as Int;
      b0 = b0 & 0xFF;
      b1 = b1 & 0xFF;
      b2 = b2 & 0xFF;
      buf[out]     = xiom_char_at(_B64U_ALPHABET, (b0 >> 2) & 63) as UInt8;
      buf[out + 1] = xiom_char_at(_B64U_ALPHABET, ((b0 << 4) | (b1 >> 4)) & 63) as UInt8;
      buf[out + 2] = xiom_char_at(_B64U_ALPHABET, ((b1 << 2) | (b2 >> 6)) & 63) as UInt8;
      buf[out + 3] = xiom_char_at(_B64U_ALPHABET, b2 & 63) as UInt8;
      out = out + 4;
      i = i + 3;
    };
    if i < len {
      var b0 = data[i] as Int;
      var b1: Int = 0;
      var b2: Int = 0;
      b0 = b0 & 0xFF;
      var has_one = i + 1 < len;
      var has_two = i + 2 < len;
      if has_one {
        b1 = data[i + 1] as Int;
        b1 = b1 & 0xFF;
      };
      if has_two {
        b2 = data[i + 2] as Int;
        b2 = b2 & 0xFF;
      };
      buf[out]     = xiom_char_at(_B64U_ALPHABET, (b0 >> 2) & 63) as UInt8;
      buf[out + 1] = xiom_char_at(_B64U_ALPHABET, ((b0 << 4) | (b1 >> 4)) & 63) as UInt8;
      if has_one {
        buf[out + 2] = xiom_char_at(_B64U_ALPHABET, ((b1 << 2) | (b2 >> 6)) & 63) as UInt8;
        out = out + 3;
      } else {
        out = out + 2;
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

/// Encodes a string's UTF-8 bytes as URL-safe base64. Complexity: O(n).
pub fn base64url_encode_str(s: Str) -> Str {
  var bytes = Vec[UInt8].new();
  var i: Int = 0;
  let slen = s.len();
  while i < slen {
    var c = s.char_at(i);
    xiom.char.encode_utf8(c, &bytes);
    i = i + xiom.char.len_utf8(c);
  };
  base64url_encode(&bytes)
}

/// Decodes URL-safe base64 into a UTF-8 string (bytes copied verbatim; the
/// caller is responsible for the UTF-8 validity of the decoded content).
/// Returns Err on invalid base64url. Complexity: O(n).
pub fn base64url_decode_str(s: Str) -> Result[Str, Str] {
  var r = base64url_decode(s);
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
}
