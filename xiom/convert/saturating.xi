// XIOM - Conversion: Saturating
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.saturating

// Depends on: xiom.num

// ============================================================================
// Saturating integer arithmetic that clamps at the integer bounds. The
// add/sub/mul operations delegate to the canonical xiom.num.i64_*_sat
// implementations (different function names, so delegation is safe from the
// same-name miscompile); abs/pow are implemented here directly.
// ============================================================================

use xiom.num;
use xiom.core.INT_MAX;
use xiom.core.INT_MIN;

/// a + b, clamping at INT_MAX/INT_MIN on overflow. Complexity: O(1).
pub fn saturating_add(a: Int, b: Int) -> Int {
  num.i64_add_sat(a, b)
}

/// a - b, clamping at INT_MAX/INT_MIN on overflow. Complexity: O(1).
pub fn saturating_sub(a: Int, b: Int) -> Int {
  num.i64_sub_sat(a, b)
}

/// a * b, clamping at INT_MAX/INT_MIN on overflow. Complexity: O(1).
pub fn saturating_mul(a: Int, b: Int) -> Int {
  num.i64_mul_sat(a, b)
}

/// |a|, clamping to INT_MAX when a == INT_MIN (no positive representation).
/// Complexity: O(1).
pub fn saturating_abs(a: Int) -> Int {
  if a == INT_MIN {
    return INT_MAX;
  };
  if a < 0 {
    return -a;
  };
  a
}

/// a^e via square-and-multiply, clamping at INT_MAX/INT_MIN on overflow.
/// Negative exponents yield 1 (documented). Complexity: O(log e).
pub fn saturating_pow(a: Int, e: Int) -> Int {
  if e <= 0 {
    return 1;
  };
  var result: Int = 1;
  var b = a;
  var exp = e;
  while exp > 0 {
    if exp % 2 == 1 {
      result = num.i64_mul_sat(result, b);
    };
    exp = exp / 2;
    if exp > 0 {
      b = num.i64_mul_sat(b, b);
    };
  };
  result
}
