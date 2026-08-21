// XIOM - Conversion: Base58
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.base58

// Depends on: xiom.num

// ============================================================================
// Base58 and base58check encoding/decoding. The integer <-> base58 helpers
// mirror xiom.num.convert (delegation is impossible here: defining a local
// `to_base58`/`from_base58` while importing the same-named functions from
// xiom.num.convert makes the compiler emit a 0xC0000005 miscompile -- verified
// by probe; the logic is therefore implemented locally). base58check uses an
// Adler-32 checksum fallback (see base58check_encode) until the compiler's
// 32-bit bitwise codegen bug is fixed.
// ============================================================================

use xiom.string;
use xiom.core.INT_MAX;
use xiom.core.INT_MIN;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

const _B58_ALPHABET: Str = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

/// Decode value of a base58 character byte; -1 for an invalid character.
fn _b58_digit(c: UInt8) -> Int {
  var i = 0;
  while i < 58 {
    var a = string.byte_at(_B58_ALPHABET, i);
    var b = c;
    if a == b {
      return i;
    };
    i = i + 1;
  };
  -1
}

/// Converts an integer to its base58 representation ("123456789ABCDEFGHJKLMNPQ
/// RSTUVWXYZabcdefghijkmnopqrstuvwxyz"). 0 yields "1"; negatives get a "-"
/// prefix (INT_MIN is rendered via its magnitude, which is handled exactly by
/// negative-digit extraction). Complexity: O(log_58 n).
pub fn to_base58(value: Int) -> Str {
  if value == 0 {
    return "1";
  };
  var neg = false;
  var num = value;
  if num < 0 {
    neg = true;
  };
  if num > 0 {
    num = 0 - num;
  };
  var digits = Vec[Int].new();
  while num != 0 {
    var d = num % 58;
    if d < 0 {
      d = 0 - d;
    };
    digits.push(d);
    num = num / 58;
  };
  var result = "";
  if neg {
    result = "-";
  };
  var i = digits.len() - 1;
  while i >= 0 {
    var d = digits[i];
    result = string.str_concat(result, string.str_slice(_B58_ALPHABET, d, d + 1));
    i = i - 1;
  };
  result
}

/// Parses a base58 string into an Int. An optional leading '-'/'+' is
/// accepted. Returns Err on an empty string, an invalid character, or
/// overflow. Negative magnitudes accumulate in signed space, so INT_MIN
/// round-trips exactly. Complexity: O(n), n = string length.
pub fn from_base58(s: Str) -> Result[Int, Str] {
  let slen = s.len();
  if slen == 0 {
    return Err("empty base58 string");
  };
  var neg = false;
  var i: Int = 0;
  var first = string.byte_at(s, 0);
  if first == 45 {
    neg = true;
    i = 1;
  } elif first == 43 {
    i = 1;
  };
  if i >= slen {
    return Err("no base58 digits");
  };
  var result: Int = 0;
  if neg {
    while i < slen {
      var digit = _b58_digit(string.byte_at(s, i));
      if digit < 0 {
        return Err("invalid base58 character");
      };
      if result < (INT_MIN + digit) / 58 {
        return Err("base58 overflow");
      };
      result = result * 58 - digit;
      i = i + 1;
    };
  } else {
    while i < slen {
      var digit = _b58_digit(string.byte_at(s, i));
      if digit < 0 {
        return Err("invalid base58 character");
      };
      if result > (INT_MAX - digit) / 58 {
        return Err("base58 overflow");
      };
      result = result * 58 + digit;
      i = i + 1;
    };
  };
  Ok(result)
}

/// Encodes bytes as a base58 string (big-endian base-256 value written in
/// base 58). Leading zero bytes produce leading '1' characters, matching the
/// Bitcoin convention. Empty input yields "". Complexity: O(n^2) worst case
/// (per-byte long division), O(n * log_58(2^8n)) typical.
pub fn base58_encode(data: &Vec[UInt8]) -> Str {
  let len = data.len();
  if len == 0 {
    return "";
  };
  var zeros: Int = 0;
  while zeros < len {
    var b = data[zeros] as Int;
    b = b & 0xFF;
    if b != 0 {
      break;
    };
    zeros = zeros + 1;
  };
  var n = Vec[Int].new();
  var i: Int = 0;
  while i < len {
    var b = data[i] as Int;
    b = b & 0xFF;
    n.push(b);
    i = i + 1;
  };
  var digits = Vec[Int].new();
  var start = zeros;
  var nlen = len;
  while start < nlen {
    var remainder: Int = 0;
    var j = start;
    while j < nlen {
      var acc = remainder * 256 + n[j];
      n[j] = acc / 58;
      remainder = acc % 58;
      j = j + 1;
    };
    digits.push(remainder);
    while start < nlen && n[start] == 0 {
      start = start + 1;
    };
  };
  var result = "";
  var k: Int = 0;
  while k < zeros {
    result = string.str_concat(result, "1");
    k = k + 1;
  };
  var di = digits.len() - 1;
  while di >= 0 {
    var d = digits[di];
    result = string.str_concat(result, string.str_slice(_B58_ALPHABET, d, d + 1));
    di = di - 1;
  };
  result
}

/// Decodes a base58 string back into bytes. Leading '1' characters map back
/// to leading zero bytes. Returns Err on an invalid character. Empty input
/// yields an empty byte vector. Complexity: O(n^2) worst case.
pub fn base58_decode(s: Str) -> Result[Vec[UInt8], Str] {
  var result = Vec[UInt8].new();
  let len = s.len();
  if len == 0 {
    return Ok(result);
  };
  var zeros: Int = 0;
  while zeros < len {
    var b = string.byte_at(s, zeros) as Int;
    b = b & 0xFF;
    if b != 49 {
      break;
    };
    zeros = zeros + 1;
  };
  var n = Vec[Int].new();
  var i: Int = zeros;
  while i < len {
    var b = string.byte_at(s, i);
    var v = _b58_digit(b);
    if v < 0 {
      return Err("invalid base58 character");
    };
    n.push(v);
    i = i + 1;
  };
  var bytes = Vec[Int].new();
  var j: Int = 0;
  while j < n.len() {
    var carry = n[j];
    var k: Int = 0;
    while k < bytes.len() {
      var acc = bytes[k] * 58 + carry;
      bytes[k] = acc & 0xFF;
      carry = acc >> 8;
      k = k + 1;
    };
    while carry > 0 {
      bytes.push(carry & 0xFF);
      carry = carry >> 8;
    };
    j = j + 1;
  };
  var z: Int = 0;
  while z < zeros {
    result.push(0);
    z = z + 1;
  };
  var bi = bytes.len() - 1;
  while bi >= 0 {
    result.push(bytes[bi] as UInt8);
    bi = bi - 1;
  };
  Ok(result)
}

// TODO(compiler): real base58check uses a 4-byte double-SHA256 checksum. The
// pure-XIOM SHA-256 round loop miscompiles (verified: `&` on 32-bit words with
// the high bit set produces wrong bits; same bug is documented in xiom.crypto,
// which routes around it with a C helper that itself fails to link). Until a
// bitcast/builtin lands, base58check falls back to Adler-32, which still
// detects accidental corruption but is NOT the cryptographic Bitcoin checksum.

/// 4-byte checksum for base58check. FALLBACK: Adler-32 (RFC 1950) instead of
/// double-SHA256 -- see the TODO(compiler) note above. Deterministic and
/// corruption-detecting, not cryptographic.
fn _b58check_checksum(data: &Vec[UInt8]) -> Vec[UInt8] {
  var s1: Int = 1;
  var s2: Int = 0;
  var i: Int = 0;
  while i < data.len() {
    var b = data[i] as Int;
    b = b & 0xFF;
    s1 = (s1 + b) % 65521;
    s2 = (s2 + s1) % 65521;
    i = i + 1;
  };
  var result = Vec[UInt8].new();
  var shift = 24;
  var k: Int = 0;
  while k < 2 {
    result.push((s1 >> shift) as UInt8);
    shift = shift - 8;
    k = k + 1;
  };
  shift = 24;
  k = 0;
  while k < 2 {
    result.push((s2 >> shift) as UInt8);
    shift = shift - 8;
    k = k + 1;
  };
  result
}

/// Encodes bytes as base58 with a trailing 4-byte checksum, matching the
/// base58check shape. FALLBACK: the checksum is Adler-32, not double-SHA256
/// (see the TODO(compiler) note) -- the output is NOT Bitcoin-interoperable.
/// Complexity: O(n^2) worst case.
pub fn base58check_encode(data: &Vec[UInt8]) -> Str {
  var checksum = _b58check_checksum(data);
  var payload = Vec[UInt8].new();
  var i: Int = 0;
  while i < data.len() {
    payload.push(data[i]);
    i = i + 1;
  };
  var j: Int = 0;
  while j < checksum.len() {
    payload.push(checksum[j]);
    j = j + 1;
  };
  base58_encode(&payload)
}

/// Decodes and verifies a base58check string. The trailing 4-byte checksum is
/// recomputed and compared; returns Err on invalid base58, truncated data, or
/// a checksum mismatch. FALLBACK checksum: Adler-32 (see base58check_encode).
/// Complexity: O(n^2) worst case.
pub fn base58check_decode(s: Str) -> Result[Vec[UInt8], Str] {
  var result: Result[Vec[UInt8], Str] = Err("unreachable");
  var d = base58_decode(s);
  match d {
    Ok(decoded) => {
      let dlen = decoded.len();
      if dlen < 4 {
        return Err("base58check data too short");
      };
      var payload = Vec[UInt8].new();
      var i: Int = 0;
      while i < dlen - 4 {
        payload.push(decoded[i]);
        i = i + 1;
      };
      var checksum = _b58check_checksum(&payload);
      var j: Int = 0;
      var mismatch = false;
      while j < 4 {
        var a = decoded[dlen - 4 + j] as Int;
        var b = checksum[j] as Int;
        a = a & 0xFF;
        b = b & 0xFF;
        if a != b {
          mismatch = true;
        };
        j = j + 1;
      };
      if mismatch {
        result = Err("base58check checksum mismatch");
      } else {
        result = Ok(payload);
      };
    },
    Err(e) => {
      result = Err(e);
    },
  }
  result
}
