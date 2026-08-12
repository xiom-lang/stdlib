// XIOM - Conversion: Unchecked
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.unchecked

// Depends on: xiom.num

// ============================================================================
// Unchecked integer arithmetic: plain two's-complement operations with NO
// overflow detection. The caller guarantees the results fit. Shift amounts
// are masked to [0, 64).
// ============================================================================

/// a + b without overflow checking (wraps). Complexity: O(1).
pub fn unchecked_add(a: Int, b: Int) -> Int {
  a + b
}

/// a - b without overflow checking (wraps). Complexity: O(1).
pub fn unchecked_sub(a: Int, b: Int) -> Int {
  a - b
}

/// a * b without overflow checking (wraps). Complexity: O(1).
pub fn unchecked_mul(a: Int, b: Int) -> Int {
  a * b
}

/// a << n without overflow checking (discards shifted-out bits); n is masked
/// to [0, 64). Complexity: O(1).
pub fn unchecked_shl(a: Int, n: Int) -> Int {
  var k = n % 64;
  if k < 0 {
    k = k + 64;
  };
  a << k
}

/// a >> n (arithmetic) without overflow checking; n is masked to [0, 64).
/// Complexity: O(1).
pub fn unchecked_shr(a: Int, n: Int) -> Int {
  var k = n % 64;
  if k < 0 {
    k = k + 64;
  };
  a >> k
}
