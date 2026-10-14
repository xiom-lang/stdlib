// XIOM - Encoding: Ascii85
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
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

// Raw byte read at `i` (wave 138): the function-shaped cached-pointer read
// (the wave-136 pattern -- an inline `unsafe { }` VALUE expression misbehaved
// on the pin). Complexity: O(1).
fn _a85_raw_byte(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

// Runtime-`xiom_char_at`-equivalent UTF-8 decode over a cached (base, len)
// view (copied from the wave-136 xiom.encoding helper; xiom_char_at strnlens
// per call, so the per-position codec loops were quadratic). Complexity: O(1).
fn _a85_char_at_runtime(base: *UInt8, len: Int, pos: Int) -> Char {
  if pos < 0 || pos >= len {
    return to_char(0);
  }
  var b0 = (_a85_raw_byte(base, pos) as Int) & 0xFF;
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
      cb = (_a85_raw_byte(base, pos + i) as Int) & 0xFF;
    }
    if (cb & 0xC0) != 0x80 {
      return to_char(b0);
    }
    cp = (cp << 6) | (cb & 0x3F);
    i = i + 1;
  }
  return to_char(cp);
}

/// Encodes bytes as an Ascii85 string ('!'..'u'; runs of four zero bytes
/// collapse to 'z'). Empty input yields "". Complexity: O(n).
pub fn ascii85_encode(data: &Vec[UInt8]) -> Str
  ensures: (data.len() == 0) => (result.len() == 0)
  ensures: result.len() <= ((data.len() + 3) / 4) * 5
{
  xiom.convert.ascii85.to_ascii85(data)
}

/// Decodes an Ascii85 string back into bytes. Accepts 'z' for zero runs.
/// Returns Err on an invalid character, a 'z' inside a group, an out-of-range
/// group value, or a degenerate tail group. Complexity: O(n).
pub fn ascii85_decode(s: Str) -> Result[Vec[UInt8], Str]
  ensures: (s.len() == 0) => (result.is_ok)
  ensures: result is Ok => result.len() <= 4 * s.len()
{
  xiom.convert.ascii85.from_ascii85(s)
}

/// Encodes a string's UTF-8 bytes as Ascii85. Complexity: O(n).
pub fn ascii85_encode_str(s: Str) -> Str
  ensures: (s.len() == 0) => (result.len() == 0)
{
  var bytes = Vec[UInt8].new();
  var i = 0;
  let slen = s.len();
  let base = s.c_str();
  while i < slen {
    var c = _a85_char_at_runtime(base, slen, i);
    xiom.char.encode_utf8(c, &bytes);
    i = i + xiom.char.len_utf8(c);
  };
  xiom.convert.ascii85.to_ascii85(&bytes)
}

/// Decodes Ascii85 into a UTF-8 string (bytes copied verbatim; the caller is
/// responsible for the UTF-8 validity of the decoded content). Returns Err on
/// invalid Ascii85. Complexity: O(n).
pub fn ascii85_decode_str(s: Str) -> Result[Str, Str]
  ensures: (s.len() == 0) => (result.is_ok)
  ensures: result is Ok => result.len() <= 4 * s.len()
{
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
pub fn ascii85_encode_with_delim(data: &Vec[UInt8]) -> Str
  ensures: result.len() >= 4
  ensures: result.len() <= ((data.len() + 3) / 4) * 5 + 4
{
  string.str_concat(string.str_concat("<~", xiom.convert.ascii85.to_ascii85(data)), "~>")
}

/// Decodes an Ascii85 string that is wrapped in the Adobe delimiters "<~" and
/// "~>". Returns Err if the delimiters are missing or the payload is invalid.
/// Complexity: O(n).
pub fn ascii85_decode_with_delim(s: Str) -> Result[Vec[UInt8], Str]
  ensures: (s.len() < 4) => (result.is_err)
  ensures: result is Ok => result.len() <= 4 * s.len()
{
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
