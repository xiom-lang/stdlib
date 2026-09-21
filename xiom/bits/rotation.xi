// XIOM - Bits: Rotation
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.bits.rotation

// Depends on: none

// ============================================================================
// Bit rotation with carry, immediate, and masked variants. Carry rotations
// are computed one bit at a time (up to 63 steps). Masked rotations rotate
// only the bits selected by a mask, within the span of those bits.
// ============================================================================

/// Circular left rotation by k bits (the shift amount is reduced mod 64).
/// Complexity: O(1).
pub fn rotate_left(n: Int, k: Int) -> Int {
  var shift = k % 64;
  if shift < 0 {
    shift = shift + 64;
  };
  if shift == 0 {
    return n;
  };
  (n << shift) | (n >> (64 - shift))
}

/// Circular right rotation by k bits (the shift amount is reduced mod 64).
/// Complexity: O(1).
pub fn rotate_right(n: Int, k: Int) -> Int {
  var shift = k % 64;
  if shift < 0 {
    shift = shift + 64;
  };
  if shift == 0 {
    return n;
  };
  (n >> shift) | (n << (64 - shift))
}

/// Rotate-left-with-carry: performs k rotate-through-carry steps (each step
/// moves bit 63 into the carry and shifts the carry into bit 0). Returns
/// (rotated_value, new_carry). The shift amount is reduced mod 64.
/// Complexity: O(k).
pub fn rotate_left_carry(n: Int, k: Int, carry_in: Int) -> (Int, Int)
  ensures: result.1 == 0 || result.1 == 1
{
  var shift = k % 64;
  if shift < 0 {
    shift = shift + 64;
  };
  var result = n;
  var c = carry_in & 1;
  var i: Int = 0;
  while i < shift {
    var top = (result >> 63) & 1;
    result = (result << 1) | c;
    c = top;
    i = i + 1;
  };
  (result, c)
}

/// Rotate-right-with-carry: performs k rotate-through-carry steps (each step
/// moves bit 0 into the carry and shifts the carry into bit 63). Returns
/// (rotated_value, new_carry). The shift amount is reduced mod 64.
/// Complexity: O(k).
pub fn rotate_right_carry(n: Int, k: Int, carry_in: Int) -> (Int, Int)
  ensures: result.1 == 0 || result.1 == 1
{
  var shift = k % 64;
  if shift < 0 {
    shift = shift + 64;
  };
  var result = n;
  var c = carry_in & 1;
  var i: Int = 0;
  while i < shift {
    var bottom = result & 1;
    result = (result >> 1) | (c << 63);
    c = bottom;
    i = i + 1;
  };
  (result, c)
}

/// Rotate left by a "compile-time constant" k (equivalent to rotate_left; the
/// language has no distinct immediate form). Complexity: O(1).
pub fn rol_imm(n: Int, k: Int) -> Int {
  rotate_left(n, k)
}

/// Rotate right by a "compile-time constant" k (equivalent to rotate_right).
/// Complexity: O(1).
pub fn ror_imm(n: Int, k: Int) -> Int {
  rotate_right(n, k)
}

/// Alias of rotate_left. Complexity: O(1).
pub fn bit_rotate_left(n: Int, k: Int) -> Int {
  rotate_left(n, k)
}

/// Alias of rotate_right. Complexity: O(1).
pub fn bit_rotate_right(n: Int, k: Int) -> Int {
  rotate_right(n, k)
}

/// Rotates left only the bits selected by `mask`; the rotation happens within
/// the span of the selected bit positions and unselected bits are unchanged.
/// The shift amount is reduced mod (number of selected bits).
/// Complexity: O(64 + popcount(mask)).
pub fn masked_rotate_left(n: Int, k: Int, mask: Int) -> Int {
  if mask == 0 {
    return n;
  };
  var bits = Vec[Int].new();
  var i: Int = 0;
  while i < 64 {
    if (mask >> i) & 1 == 1 {
      bits.push((n >> i) & 1);
    };
    i = i + 1;
  };
  var count = bits.len();
  if count == 0 {
    return n;
  };
  var shift = k % count;
  if shift < 0 {
    shift = shift + count;
  };
  var out = n;
  i = 0;
  while i < 64 {
    if (mask >> i) & 1 == 1 {
      var bit = (out >> i) & 1;
      if bit == 1 {
        var one: Int = 1;
        out = out - (one << i);
      };
    };
    i = i + 1;
  };
  var pos: Int = 0;
  i = 0;
  while i < 64 {
    if (mask >> i) & 1 == 1 {
      var src = pos - shift + count;
      if src >= count {
        src = src - count;
      };
      var bitv = bits[src];
      if bitv == 1 {
        var one: Int = 1;
        out = out + (one << i);
      };
      pos = pos + 1;
    };
    i = i + 1;
  };
  out
}

/// Rotates right only the bits selected by `mask` (inverse of
/// masked_rotate_left). The shift amount is reduced mod (number of selected
/// bits). Complexity: O(64 + popcount(mask)).
pub fn masked_rotate_right(n: Int, k: Int, mask: Int) -> Int {
  if mask == 0 {
    return n;
  };
  var bits = Vec[Int].new();
  var i: Int = 0;
  while i < 64 {
    if (mask >> i) & 1 == 1 {
      bits.push((n >> i) & 1);
    };
    i = i + 1;
  };
  var count = bits.len();
  if count == 0 {
    return n;
  };
  var shift = k % count;
  if shift < 0 {
    shift = shift + count;
  };
  var out = n;
  i = 0;
  while i < 64 {
    if (mask >> i) & 1 == 1 {
      var bit = (out >> i) & 1;
      if bit == 1 {
        var one: Int = 1;
        out = out - (one << i);
      };
    };
    i = i + 1;
  };
  var pos: Int = 0;
  i = 0;
  while i < 64 {
    if (mask >> i) & 1 == 1 {
      var src = pos + shift;
      if src >= count {
        src = src - count;
      };
      var bitv = bits[src];
      if bitv == 1 {
        var one: Int = 1;
        out = out + (one << i);
      };
      pos = pos + 1;
    };
    i = i + 1;
  };
  out
}
