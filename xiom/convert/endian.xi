// XIOM - Conversion: Endian
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.endian

// Depends on: xiom.bits (swap primitive), xiom.serialize.endian (canonical)
//
// DEPRECATED TWIN (dedup unit, 2026-09-12): this module is now a thin
// compatibility surface over the canonical xiom.serialize.endian writers and
// readers; new code should use xiom.serialize.endian directly. The 8-byte
// Int forms below are the frozen legacy API and are pinned by
// smoke_convert_endian (twin-vs-vectors; see STDLIB_DEDUP_INVENTORY.md).

use xiom.bits;
use xiom.serialize.endian as sendian;

/// Big-endian byte representation of an integer (exactly 8 bytes, MSB first).
/// Negative values render as their two's-complement pattern.
/// Complexity: O(1).
pub fn to_be_bytes(n: Int) -> Vec[UInt8] {
  var out = Vec[UInt8].new();
  sendian.write_u64_be(&mut out, n as UInt64);
  return out;
}

/// Little-endian byte representation of an integer (exactly 8 bytes, LSB
/// first). Complexity: O(1).
pub fn to_le_bytes(n: Int) -> Vec[UInt8] {
  var out = Vec[UInt8].new();
  sendian.write_u64_le(&mut out, n as UInt64);
  return out;
}

/// Integer read from big-endian bytes. Reads at most 8 bytes; returns 0 for
/// an empty vector or more than 8 bytes. Complexity: O(n).
pub fn from_be_bytes(bytes: &Vec[UInt8]) -> Int {
  var len = bytes.len();
  if len == 0 || len > 8 {
    return 0;
  };
  if len == 8 {
    return sendian.read_u64_be(bytes, 0) as Int;
  };
  var result: Int = 0;
  var i: Int = 0;
  while i < len {
    var b = bytes[i] as Int;
    b = b & 0xFF;
    result = result * 256 + b;
    i = i + 1;
  };
  return result;
}

/// Integer read from little-endian bytes. Reads at most 8 bytes; returns 0
/// for an empty vector or more than 8 bytes. Complexity: O(n).
pub fn from_le_bytes(bytes: &Vec[UInt8]) -> Int {
  var len = bytes.len();
  if len == 0 || len > 8 {
    return 0;
  };
  if len == 8 {
    return sendian.read_u64_le(bytes, 0) as Int;
  };
  var result: Int = 0;
  var i = len - 1;
  while i >= 0 {
    var b = bytes[i] as Int;
    b = b & 0xFF;
    result = result * 256 + b;
    i = i - 1;
  };
  return result;
}

/// Reverses the byte order of an integer (all 8 bytes). Delegates to the
/// canonical xiom.bits.byte_swap64. Complexity: O(1).
pub fn swap_bytes(n: Int) -> Int {
  bits.byte_swap64(n)
}

/// Reports the host byte order. The supported x86-64 targets are
/// little-endian, so this returns true. Complexity: O(1).
pub fn is_little_endian() -> Bool {
  true
}

