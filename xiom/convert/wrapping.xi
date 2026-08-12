// XIOM - Conversion: Wrapping
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.wrapping

// Depends on: xiom.num

// ============================================================================
// Wrapping integer arithmetic: results truncate (wrap) at the 64-bit
// two's-complement boundary. Shift amounts are masked to [0, 64).
// ============================================================================

/// a + b, wrapping on overflow (two's complement). Complexity: O(1).
pub fn wrapping_add(a: Int, b: Int) -> Int {
  a + b
}

/// a - b, wrapping on underflow. Complexity: O(1).
pub fn wrapping_sub(a: Int, b: Int) -> Int {
  a - b
}

/// a * b, wrapping on overflow. Complexity: O(1).
pub fn wrapping_mul(a: Int, b: Int) -> Int {
  a * b
}

/// -a, wrapping on overflow (INT_MIN negates to itself). Complexity: O(1).
pub fn wrapping_neg(a: Int) -> Int {
  0 - a
}

/// |a|, wrapping on overflow (INT_MIN maps to itself). Complexity: O(1).
pub fn wrapping_abs(a: Int) -> Int {
  if a < 0 {
    return 0 - a;
  };
  a
}

/// a << n with the shift amount masked to [0, 64); shifted-out bits are
/// discarded. Complexity: O(1).
pub fn wrapping_shl(a: Int, n: Int) -> Int {
  var k = n % 64;
  if k < 0 {
    k = k + 64;
  };
  a << k
}

/// a >> n (arithmetic) with the shift amount masked to [0, 64); shifted-out
/// bits are discarded. Complexity: O(1).
pub fn wrapping_shr(a: Int, n: Int) -> Int {
  var k = n % 64;
  if k < 0 {
    k = k + 64;
  };
  a >> k
}
