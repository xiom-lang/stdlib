// XIOM - Conversion: Base64Url
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.base64url

// Depends on: xiom.encoding.base64

// ============================================================================
// DEPRECATED (dedup wave, 2026-09-15): thin delegating shim over
// xiom.encoding.base64 (canonical unpadded URL-safe base64). The byte legs
// delegate; the string wrappers stay local because the canonical module does
// not expose url-safe str variants yet.
//
// Same-name delegation through the `enc_b64` alias is safe since the R20 fix
// (a2a456c4, m75 lock); the alias avoids the R9 leaf-shadowing hazard.
// ============================================================================

use xiom.encoding.base64 as enc_b64;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
}

/// Encodes bytes as an unpadded URL-safe base64 string (alphabet A-Za-z0-9-_).
/// Empty input yields "". Complexity: O(n).
pub fn base64url_encode(data: &Vec[UInt8]) -> Str {
  return enc_b64.base64url_encode(data);
}

/// Decodes an unpadded URL-safe base64 string to bytes. Optional '=' padding
/// is tolerated. Returns Err on an invalid character. Complexity: O(n).
pub fn base64url_decode(s: Str) -> Result[Vec[UInt8], Str] {
  return enc_b64.base64url_decode(s);
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
  enc_b64.base64url_encode(&bytes)
}

/// Decodes URL-safe base64 into a UTF-8 string (bytes copied verbatim; the
/// caller is responsible for the UTF-8 validity of the decoded content).
/// Returns Err on invalid base64url. Complexity: O(n).
pub fn base64url_decode_str(s: Str) -> Result[Str, Str] {
  var r = enc_b64.base64url_decode(s);
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
