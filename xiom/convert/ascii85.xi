// XIOM - Conversion: Ascii85
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.convert.ascii85

// Depends on: xiom.num

// ============================================================================
// Ascii85 (Adobe base85, RFC 1924) encoding/decoding. Groups of four bytes
// are encoded as five characters in the range '!'..'u'; a run of four zero
// bytes encodes as the single character 'z'. Implemented locally (same-name
// delegation to xiom.num.convert crashes the compiler -- see xiom.convert
// .base58 for the probe reference).
// ============================================================================

use xiom.string;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

const _A85_ALPHABET: Str = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_\x60abcdefghijklmnopqrstuvwxyz";

/// Encodes one 32-bit value as exactly five Ascii85 characters ('!'..'u').
fn _a85_group(value: Int) -> Str {
  var v = value;
  var d4 = v % 85;
  v = v / 85;
  var d3 = v % 85;
  v = v / 85;
  var d2 = v % 85;
  v = v / 85;
  var d1 = v % 85;
  v = v / 85;
  var d0 = v % 85;
  var result = "";
  result = string.str_concat(result, string.str_slice(_A85_ALPHABET, d0, d0 + 1));
  result = string.str_concat(result, string.str_slice(_A85_ALPHABET, d1, d1 + 1));
  result = string.str_concat(result, string.str_slice(_A85_ALPHABET, d2, d2 + 1));
  result = string.str_concat(result, string.str_slice(_A85_ALPHABET, d3, d3 + 1));
  result = string.str_concat(result, string.str_slice(_A85_ALPHABET, d4, d4 + 1));
  result
}

/// Encodes bytes as an Ascii85 string. Runs of four zero bytes collapse to
/// 'z'; a final partial group is padded with zero bytes on the right and only
/// the needed characters are emitted. Empty input yields "". Complexity: O(n).
pub fn to_ascii85(data: &Vec[UInt8]) -> Str {
  var result = "";
  let len = data.len();
  if len == 0 {
    return result;
  };
  var i: Int = 0;
  while i < len {
    var remaining = len - i;
    if remaining >= 4 {
      var value = 0;
      var k: Int = 0;
      while k < 4 {
        var b = data[i + k] as Int;
        b = b & 0xFF;
        value = value * 256 + b;
        k = k + 1;
      };
      if value == 0 {
        result = string.str_concat(result, "z");
      } else {
        result = string.str_concat(result, _a85_group(value));
      };
      i = i + 4;
    } else {
      var b0: Int = 0;
      var b1: Int = 0;
      var b2: Int = 0;
      var bb0 = data[i] as Int;
      b0 = bb0 & 0xFF;
      if remaining >= 2 {
        var bb1 = data[i + 1] as Int;
        b1 = bb1 & 0xFF;
      };
      if remaining >= 3 {
        var bb2 = data[i + 2] as Int;
        b2 = bb2 & 0xFF;
      };
      var value = (b0 * 16777216) + (b1 * 65536) + (b2 * 256);
      var group = _a85_group(value);
      result = string.str_concat(result, string.str_slice(group, 0, remaining + 1));
      i = i + remaining;
    };
  };
  result
}

/// Decode value of an Ascii85 character byte; -1 for an invalid character.
fn _a85_digit(c: UInt8) -> Int {
  var code = c as Int;
  code = code & 0xFF;
  if code < 33 || code > 117 {
    return -1;
  };
  code - 33
}

/// Decodes an Ascii85 string back into bytes. Accepts 'z' for zero runs.
/// Returns Err on an invalid character, a 'z' inside a group, an out-of-range
/// group value, or a degenerate tail group. Complexity: O(n).
pub fn from_ascii85(s: Str) -> Result[Vec[UInt8], Str] {
  var result = Vec[UInt8].new();
  let len = s.len();
  if len == 0 {
    return Ok(result);
  };
  var i: Int = 0;
  while i < len {
    var c = string.byte_at(s, i);
    if c == 122 {
      result.push(0);
      result.push(0);
      result.push(0);
      result.push(0);
      i = i + 1;
    } else {
      var value: Int = 0;
      var count: Int = 0;
      while count < 5 && i < len {
        var ch = string.byte_at(s, i);
        if ch == 122 {
          return Err("invalid 'z' inside ascii85 group");
        };
        var digit = _a85_digit(ch);
        if digit < 0 {
          return Err("invalid ascii85 character");
        };
        value = value * 85 + digit;
        count = count + 1;
        i = i + 1;
      };
      var pos = count;
      while pos < 5 {
        value = value * 85 + 84;
        pos = pos + 1;
      };
      if count == 5 && value > 4294967295 {
        return Err("ascii85 group value out of range");
      };
      if count == 5 {
        result.push((value >> 24) as UInt8);
        result.push((value >> 16) as UInt8);
        result.push((value >> 8) as UInt8);
        result.push(value as UInt8);
      } elif count == 4 {
        result.push((value >> 24) as UInt8);
        result.push((value >> 16) as UInt8);
        result.push((value >> 8) as UInt8);
      } elif count == 3 {
        result.push((value >> 24) as UInt8);
        result.push((value >> 16) as UInt8);
      } elif count == 2 {
        result.push((value >> 24) as UInt8);
      } else {
        return Err("degenerate ascii85 tail group");
      };
    };
  };
  Ok(result)
}

/// Encodes a string's UTF-8 bytes as Ascii85. Complexity: O(n).
pub fn ascii85_encode_str(s: Str) -> Str {
  var bytes = Vec[UInt8].new();
  var i: Int = 0;
  let slen = s.len();
  while i < slen {
    var c = s.char_at(i);
    xiom.char.encode_utf8(c, &bytes);
    i = i + xiom.char.len_utf8(c);
  };
  to_ascii85(&bytes)
}

/// Decodes Ascii85 into a UTF-8 string (bytes copied verbatim; the caller is
/// responsible for the UTF-8 validity of the decoded content). Returns Err on
/// invalid Ascii85. Complexity: O(n).
pub fn ascii85_decode_str(s: Str) -> Result[Str, Str] {
  var r = from_ascii85(s);
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
