// XIOM - Hashing: Adler-32
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.hash.adler

// Depends on: none

// ============================================================================
// Adler-32 is a fast rolling checksum, weaker than CRC-32 but useful for
// streaming and delta checks where cheap recomputation matters. The modulo-65521
// arithmetic follows RFC 1950; the combine operation follows zlib's
// adler32_combine.
// ============================================================================

use xiom.string;

const _ADLER_MOD: Int = 65521;

/// Computes the Adler-32 checksum over `data` (RFC 1950). The empty input
/// yields 1 (the initial A value). Check: adler32("Wikipedia") == 0x11E60398.
/// Complexity: O(n).
pub fn adler32(data: &Vec[UInt8]) -> UInt32 {
  var a: Int = 1;
  var b: Int = 0;
  var i = 0;
  var len = data.len();
  while i < len {
    a = (a + ((data[i] as Int) & 0xFF)) % _ADLER_MOD;
    b = (b + a) % _ADLER_MOD;
    i = i + 1;
  };
  ((b << 16) | a) as UInt32
}

/// Computes the Adler-32 checksum of the raw bytes of a string (its UTF-8
/// encoding, byte by byte). Complexity: O(n).
pub fn adler32_str(s: Str) -> UInt32 {
  var a: Int = 1;
  var b: Int = 0;
  var len = s.len();
  var i = 0;
  while i < len {
    var byte = (string.byte_at(s, i) as Int) & 0xFF;
    a = (a + byte) % _ADLER_MOD;
    b = (b + a) % _ADLER_MOD;
    i = i + 1;
  };
  ((b << 16) | a) as UInt32
}

/// Combines two Adler-32 checksums as if the blocks were concatenated:
/// `a` covers the first block, `b` covers a second block of `len_b` bytes.
/// Returns 0xFFFFFFFF for a negative `len_b` (zlib convention). Complexity: O(1).
pub fn adler32_combine(a: UInt32, b: UInt32, len_b: Int) -> UInt32 {
  if len_b < 0 {
    return 0xFFFFFFFF as UInt32;
  };
  var sum1: Int = a as Int;
  var sum2: Int = 0;
  var rem = len_b % _ADLER_MOD;
  sum1 = sum1 & 0xFFFF;
  sum2 = rem * sum1;
  sum2 = sum2 % _ADLER_MOD;
  sum1 = sum1 + ((b as Int) & 0xFFFF) + _ADLER_MOD - 1;
  sum2 = sum2 + ((a as Int) >> 16) + ((b as Int) >> 16) + _ADLER_MOD - rem;
  if sum1 >= _ADLER_MOD {
    sum1 = sum1 - _ADLER_MOD;
  };
  if sum1 >= _ADLER_MOD {
    sum1 = sum1 - _ADLER_MOD;
  };
  if sum2 >= (_ADLER_MOD << 1) {
    sum2 = sum2 - (_ADLER_MOD << 1);
  };
  if sum2 >= _ADLER_MOD {
    sum2 = sum2 - _ADLER_MOD;
  };
  (sum1 | (sum2 << 16)) as UInt32
}
