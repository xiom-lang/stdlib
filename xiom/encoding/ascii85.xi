// XIOM - Encoding: Ascii85
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.encoding.ascii85

// Depends on: xiom.string

// ============================================================================
// Adobe Ascii85 (Base85) encoding and decoding. The core codec delegates to
// xiom.convert.ascii85.to_ascii85 / from_ascii85 with FULL module-qualified
// calls: num.convert also exports a same-named `from_ascii85` returning
// Option[Vec[UInt8]], and in a combined import set the bare alias bound to
// the wrong one (compiler IR gate stdlib_all_modules_compile_to_ir, T001
// return type mismatch). The string and delimiter wrappers are local.
// ============================================================================

use xiom.string;
use xiom.convert.ascii85;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

/// Encodes bytes as an Ascii85 string ('!'..'u'; runs of four zero bytes
/// collapse to 'z'). Empty input yields "". Complexity: O(n).
pub fn ascii85_encode(data: &Vec[UInt8]) -> Str {
  xiom.convert.ascii85.to_ascii85(data)
}

/// Decodes an Ascii85 string back into bytes. Accepts 'z' for zero runs.
/// Returns Err on an invalid character, a 'z' inside a group, an out-of-range
/// group value, or a degenerate tail group. Complexity: O(n).
pub fn ascii85_decode(s: Str) -> Result[Vec[UInt8], Str] {
  xiom.convert.ascii85.from_ascii85(s)
}

/// Encodes a string's UTF-8 bytes as Ascii85. Complexity: O(n).
pub fn ascii85_encode_str(s: Str) -> Str {
  var bytes = Vec[UInt8].new();
  var i = 0;
  let slen = s.len();
  while i < slen {
    var c = s.char_at(i);
    xiom.char.encode_utf8(c, &bytes);
    i = i + xiom.char.len_utf8(c);
  };
  xiom.convert.ascii85.to_ascii85(&bytes)
}

/// Decodes Ascii85 into a UTF-8 string (bytes copied verbatim; the caller is
/// responsible for the UTF-8 validity of the decoded content). Returns Err on
/// invalid Ascii85. Complexity: O(n).
pub fn ascii85_decode_str(s: Str) -> Result[Str, Str] {
  var r = xiom.convert.ascii85.from_ascii85(s);
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

/// Encodes bytes as Ascii85 wrapped in the Adobe delimiters "<~" and "~>".
/// Complexity: O(n).
pub fn ascii85_encode_with_delim(data: &Vec[UInt8]) -> Str {
  string.str_concat(string.str_concat("<~", xiom.convert.ascii85.to_ascii85(data)), "~>")
}

/// Decodes an Ascii85 string that is wrapped in the Adobe delimiters "<~" and
/// "~>". Returns Err if the delimiters are missing or the payload is invalid.
/// Complexity: O(n).
pub fn ascii85_decode_with_delim(s: Str) -> Result[Vec[UInt8], Str] {
  let len = s.len();
  if len < 4 {
    return Err("ascii85 delimiters missing");
  };
  if !string.str_starts_with(s, "<~") {
    return Err("ascii85 opening delimiter missing");
  };
  if !string.str_ends_with(s, "~>") {
    return Err("ascii85 closing delimiter missing");
  };
  let inner = string.str_slice(s, 2, len - 2);
  xiom.convert.ascii85.from_ascii85(inner)
}
