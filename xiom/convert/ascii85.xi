// XIOM - Conversion: Ascii85
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

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

// Raw byte read at `i` (wave 138): the function-shaped cached-pointer read
// (the wave-136 pattern -- an inline `unsafe { }` VALUE expression misbehaved
// on the pin). Complexity: O(1).
fn _ca85_raw_byte(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

// Runtime-`xiom_char_at`-equivalent UTF-8 decode over a cached (base, len)
// view (copied from the wave-136 xiom.encoding helper). Complexity: O(1).
fn _ca85_char_at_runtime(base: *UInt8, len: Int, pos: Int) -> Char {
  if pos < 0 || pos >= len {
    return to_char(0);
  }
  var b0 = (_ca85_raw_byte(base, pos) as Int) & 0xFF;
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
      cb = (_ca85_raw_byte(base, pos + i) as Int) & 0xFF;
    }
    if (cb & 0xC0) != 0x80 {
      return to_char(b0);
    }
    cp = (cp << 6) | (cb & 0x3F);
    i = i + 1;
  }
  return to_char(cp);
}

// Builds a Str from UTF-8 bytes (single allocation, NUL-terminated). Wave
// 138: the encoder previously grew its result with str_concat PER GROUP --
// quadratic time and leaked intermediate strings (the 512 KB scratch blew
// through the 1.5 GB cap); new code builds through one Vec.
fn _ca85_vec_to_str(bytes: &Vec[UInt8]) -> Str {
  var len = bytes.len();
  if len == 0 {
    return "";
  };
  unsafe {
    var buf = malloc(len + 1);
    var i = 0;
    while i < len {
      buf[i] = bytes[i];
      i = i + 1;
    };
    buf[len] = 0;
    return Str.from_cstring(buf);
  }
}

const _A85_ALPHABET: Str = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_\x60abcdefghijklmnopqrstuvwxyz";

/// Appends `count` (1..5) Ascii85 characters for `value` (0..2^32-1) to
/// `out`; `abase` is the cached alphabet pointer. Wave 138: writes the
/// digits straight into the output Vec (the old Str-building variant
/// allocated six strings per group).
fn _ca85_push_group(out: &mut Vec[UInt8], abase: *UInt8, value: Int, count: Int)
  requires: count >= 1 && count <= 5
{
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
  out.push(_ca85_raw_byte(abase, d0));
  if count > 1 {
    out.push(_ca85_raw_byte(abase, d1));
  };
  if count > 2 {
    out.push(_ca85_raw_byte(abase, d2));
  };
  if count > 3 {
    out.push(_ca85_raw_byte(abase, d3));
  };
  if count > 4 {
    out.push(_ca85_raw_byte(abase, d4));
  };
}

/// Encodes bytes as an Ascii85 string. Runs of four zero bytes collapse to
/// 'z'; a final partial group is padded with zero bytes on the right and only
/// the needed characters are emitted. Empty input yields "". Complexity: O(n).
pub fn to_ascii85(data: &Vec[UInt8]) -> Str
  ensures: (data.len() == 0) => (result == "")
{
  let len = data.len();
  if len == 0 {
    return "";
  };
  let abase = _A85_ALPHABET.c_str();
  var out = Vec[UInt8].new();
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
        out.push(122 as UInt8);
      } else {
        _ca85_push_group(&mut out, abase, value, 5);
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
      _ca85_push_group(&mut out, abase, value, remaining + 1);
      i = i + remaining;
    };
  };
  _ca85_vec_to_str(&out)
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
pub fn from_ascii85(s: Str) -> Result[Vec[UInt8], Str]
  ensures: (s.len() == 0) => (result.is_ok == true)
{
  var result = Vec[UInt8].new();
  let len = s.len();
  if len == 0 {
    return Ok(result);
  };
  let base = s.c_str();
  var i: Int = 0;
  while i < len {
    var c = _ca85_raw_byte(base, i);
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
        var ch = _ca85_raw_byte(base, i);
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
pub fn ascii85_encode_str(s: Str) -> Str
  ensures: (s.len() == 0) => (result == "")
{
  var bytes = Vec[UInt8].new();
  var i = 0;
  let slen = s.len();
  let base = s.c_str();
  while i < slen {
    var c = _ca85_char_at_runtime(base, slen, i);
    xiom.char.encode_utf8(c, &bytes);
    i = i + xiom.char.len_utf8(c);
  };
  to_ascii85(&bytes)
}

/// Decodes Ascii85 into a UTF-8 string (bytes copied verbatim; the caller is
/// responsible for the UTF-8 validity of the decoded content). Returns Err on
/// invalid Ascii85. Complexity: O(n).
pub fn ascii85_decode_str(s: Str) -> Result[Str, Str]
  ensures: (s.len() == 0) => (result.is_ok == true)
{
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
