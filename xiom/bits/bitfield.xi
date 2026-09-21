// XIOM - Bits: Bitfield
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Home: bits.xi - this sublib splits the fixed-width bitfield domain.

module xiom.bits.bitfield

// Depends on: none

// ============================================================================
// Fixed-width bitfield extraction and insertion. All operations are built on
// byte-at-a-time reads/writes plus arithmetic reassembly: the compiler
// miscompiles bitwise AND on operands with bit 31 set (see xiom.convert
// .base58 for the probe reference), so wide-field masks are never ANDed
// directly.
// ============================================================================

/// Bit i of the byte containing global bit `bit` (0-7).
fn _bit_in_byte(b: Int, bit: Int) -> Int {
  var shifted = b >> bit;
  shifted & 1
}

/// Extracts `width` bits at `offset` as an unsigned, right-justified value.
/// Out-of-range requests are clamped: width <= 0 yields 0; the field is
/// truncated at bit 63. Complexity: O(width).
pub fn bitfield_get(value: Int, offset: Int, width: Int) -> Int
  ensures: result >= 0
{
  if width <= 0 {
    return 0;
  };
  if offset < 0 {
    return 0;
  };
  var w = width;
  if offset + w > 64 {
    w = 64 - offset;
  };
  if w <= 0 {
    return 0;
  };
  var result: Int = 0;
  var k: Int = 0;
  while k < w {
    var bit = offset + k;
    var j = bit / 8;
    var sh = bit % 8;
    var b = (value >> (j * 8)) & 0xFF;
    var bitv = _bit_in_byte(b, sh);
    result = result + (bitv << k);
    k = k + 1;
  };
  result
}

/// Inserts `val` (masked to the field width) into the field at `offset`,
/// leaving all other bits unchanged. The field is truncated at bit 63.
/// Complexity: O(width).
pub fn bitfield_set(value: Int, offset: Int, width: Int, val: Int) -> Int {
  if width <= 0 {
    return value;
  };
  if offset < 0 {
    return value;
  };
  var w = width;
  if offset + w > 64 {
    w = 64 - offset;
  };
  if w <= 0 {
    return value;
  };
  var bytes = Vec[Int].new();
  var j: Int = 0;
  while j < 8 {
    var b = (value >> (j * 8)) & 0xFF;
    bytes.push(b);
    j = j + 1;
  };
  var k: Int = 0;
  while k < w {
    var bit = offset + k;
    var jb = bit / 8;
    var sh = bit % 8;
    var src = (val >> k) & 1;
    var cur = bytes[jb];
    var notm = 0xFF ^ (1 << sh);
    cur = cur & notm;
    if src == 1 {
      cur = cur | (1 << sh);
    };
    bytes[jb] = cur;
    k = k + 1;
  };
  var result: Int = 0;
  j = 0;
  while j < 8 {
    result = result + (bytes[j] << (j * 8));
    j = j + 1;
  };
  result
}

/// Zeros the `width` bits at `offset`, leaving all other bits unchanged.
/// Complexity: O(width).
pub fn bitfield_clear(value: Int, offset: Int, width: Int) -> Int {
  bitfield_set(value, offset, width, 0)
}

/// Sign-extends a `width`-bit value: bit width-1 is replicated into all
/// higher bit positions. width <= 0 yields 0; width >= 64 returns value
/// unchanged. Complexity: O(width).
pub fn bitfield_sign_extend(value: Int, width: Int) -> Int {
  if width <= 0 {
    return 0;
  };
  if width >= 64 {
    return value;
  };
  var extracted = bitfield_get(value, 0, width);
  var sb = (extracted >> (width - 1)) & 1;
  if sb == 1 {
    var upper = 0 - (1 << (width - 1));
    return extracted | upper;
  };
  extracted
}

/// Mask of `width` low bits set. width <= 0 yields 0; width >= 64 yields -1
/// (all 64 bits). Complexity: O(1).
pub fn bitfield_mask(width: Int) -> Int
  ensures: width >= 1 && width <= 63 => result >= 0
{
  if width <= 0 {
    return 0;
  };
  if width >= 64 {
    return -1;
  };
  (1 << width) - 1
}

/// Unsigned field extract, right-justified (alias of bitfield_get).
/// Complexity: O(width).
pub fn bitfield_extract_u(value: Int, offset: Int, width: Int) -> Int
  ensures: result >= 0
{
  bitfield_get(value, offset, width)
}

/// Places `value` into the field of `base` at `offset` (alias of
/// bitfield_set with the arguments in insertion order).
/// Complexity: O(width).
pub fn bitfield_insert(base: Int, value: Int, offset: Int, width: Int) -> Int {
  bitfield_set(base, offset, width, value)
}
