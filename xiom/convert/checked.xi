// XIOM - Conversion: Checked
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.checked

// Depends on: xiom.num

// ============================================================================
// Overflow-checked integer arithmetic. The add/sub/mul/div operations
// delegate to the canonical xiom.num.i64_*_checked implementations (different
// function names, so delegation is safe from the same-name miscompile); the
// neg/abs/pow/shl/shr operations are implemented here directly.
// ============================================================================

use xiom.num;
use xiom.core.INT_MIN;

/// a + b, returning None on overflow. Complexity: O(1).
pub fn checked_add(a: Int, b: Int) -> Option[Int] {
  num.i64_add_checked(a, b)
}

/// a - b, returning None on overflow. Complexity: O(1).
pub fn checked_sub(a: Int, b: Int) -> Option[Int] {
  num.i64_sub_checked(a, b)
}

/// a * b, returning None on overflow. Complexity: O(1).
pub fn checked_mul(a: Int, b: Int) -> Option[Int] {
  num.i64_mul_checked(a, b)
}

/// a / b, returning None on division by zero or INT_MIN / -1.
/// Complexity: O(1).
pub fn checked_div(a: Int, b: Int) -> Option[Int] {
  num.i64_div_checked(a, b)
}

/// -a, returning None when a == INT_MIN (no positive inverse).
/// Complexity: O(1).
pub fn checked_neg(a: Int) -> Option[Int] {
  if a == INT_MIN {
    return None;
  };
  Some(-a)
}

/// |a|, returning None when a == INT_MIN (no positive representation).
/// Complexity: O(1).
pub fn checked_abs(a: Int) -> Option[Int] {
  if a == INT_MIN {
    return None;
  };
  if a < 0 {
    return Some(-a);
  };
  Some(a)
}

/// a^e via square-and-multiply, returning None on overflow or a negative
/// exponent. Complexity: O(log e).
pub fn checked_pow(a: Int, e: Int) -> Option[Int] {
  if e < 0 {
    return None;
  };
  if e == 0 {
    return Some(1);
  };
  var result: Int = 1;
  var b = a;
  var exp = e;
  while exp > 0 {
    if exp % 2 == 1 {
      var m = num.i64_mul_checked(result, b);
      if !m.is_some {
        return None;
      };
      result = m.value;
    };
    exp = exp / 2;
    if exp > 0 {
      var m2 = num.i64_mul_checked(b, b);
      if !m2.is_some {
        return None;
      };
      b = m2.value;
    };
  };
  Some(result)
}

/// a << n, returning None when bits are shifted out of the value or the shift
/// amount is outside [0, 64). Overflow is detected by verifying that an
/// arithmetic shift back reproduces a. Complexity: O(1).
pub fn checked_shl(a: Int, n: Int) -> Option[Int] {
  if n < 0 || n >= 64 {
    return None;
  };
  if n == 0 {
    return Some(a);
  };
  var result = a << n;
  var back = result >> n;
  if back != a {
    return None;
  };
  Some(result)
}

/// a >> n (arithmetic), returning None when the shift amount is outside
/// [0, 64). Complexity: O(1).
pub fn checked_shr(a: Int, n: Int) -> Option[Int] {
  if n < 0 || n >= 64 {
    return None;
  };
  Some(a >> n)
}
