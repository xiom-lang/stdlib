// XIOM - Hashing: Classic Checksums
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.hash.checksum

// Depends on: none

// ============================================================================
// Simple legacy checksum algorithms (BSD, SysV, Internet, Fletcher-16).
// Implemented locally (same-name delegation to xiom.hash.crc crashes the
// compiler -- see xiom.convert.base58 for the probe reference).
// ============================================================================

/// BSD sum: 16-bit checksum = rotate-right-1, then add each byte (mod 2^16).
/// Complexity: O(n).
pub fn checksum_bsd(data: &Vec[UInt8]) -> UInt32 {
  var sum: UInt64 = 0;
  var i = 0;
  var len = data.len();
  while i < len {
    var byte: UInt64 = (data[i] as Int) & 0xFF;
    sum = ((sum >> 1) | ((sum & 1) << 15)) & 0xFFFF;
    sum = (sum + byte) & 0xFFFF;
    i = i + 1;
  };
  sum as UInt32
}

/// SysV sum: 16-bit accumulator that rotates right by one bit after each byte
/// is added. Complexity: O(n).
pub fn checksum_sysv(data: &Vec[UInt8]) -> UInt32 {
  var sum: UInt64 = 0;
  var i = 0;
  var len = data.len();
  while i < len {
    var byte: UInt64 = (data[i] as Int) & 0xFF;
    sum = (sum + byte) & 0xFFFF;
    sum = ((sum >> 1) | ((sum & 1) << 15)) & 0xFFFF;
    i = i + 1;
  };
  sum as UInt32
}

/// Internet one's-complement checksum (RFC 1071): the one's complement of the
/// sum of 16-bit big-endian words, with end-around carry. Complexity: O(n).
pub fn checksum_internet(data: &Vec[UInt8]) -> UInt32 {
  var total: UInt64 = 0;
  var i = 0;
  var len = data.len();
  while i + 1 < len {
    var hi: UInt64 = (data[i] as Int) & 0xFF;
    var lo: UInt64 = (data[i + 1] as Int) & 0xFF;
    total = total + (hi << 8) + lo;
    i = i + 2;
  };
  if i < len {
    var hi: UInt64 = (data[i] as Int) & 0xFF;
    total = total + (hi << 8);
  };
  total = (total & 0xFFFF) + (total >> 16);
  total = (total & 0xFFFF) + (total >> 16);
  ((0xFFFF - (total & 0xFFFF)) & 0xFFFF) as UInt32
}

/// Fletcher-16 checksum: two 8-bit accumulators modulo 255, sum1 = running sum
/// of bytes, sum2 = running sum of sum1 values. The 16-bit result packs them
/// as (sum2 << 8) | sum1. Complexity: O(n).
pub fn checksum_fletcher16(data: &Vec[UInt8]) -> UInt16 {
  var sum1: Int = 0;
  var sum2: Int = 0;
  var i = 0;
  var len = data.len();
  while i < len {
    var byte = (data[i] as Int) & 0xFF;
    sum1 = (sum1 + byte) % 255;
    sum2 = (sum2 + sum1) % 255;
    i = i + 1;
  };
  ((sum2 << 8) | sum1) as UInt16
}
