// XIOM - Conversion: Overflow
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.overflow

// Depends on: xiom.num

// ============================================================================
// Overflowing integer arithmetic: each operation returns the wrapped result
// together with a Bool flag reporting whether the arithmetic overflowed.
//
// TODO(compiler): functions returning a tuple that CONTAINS a Bool cannot be
// compiled -- the compiler emits a Tuple__Int__Int where a Tuple__Int__Bool is
// expected ("invalid IR", verified by minimal probe; Bool-in-struct is fine,
// Bool-in-tuple is not). The implementations below are correct but must not
// be CALLED until the tuple/Bool codegen bug is fixed.
// ============================================================================

use xiom.num;
use xiom.core.INT_MIN;

/// a + b, returning (wrapped_value, overflowed). Complexity: O(1).
pub fn overflowing_add(a: Int, b: Int) -> (Int, Bool) {
  var r = num.i64_add_checked(a, b);
  if r.is_some {
    var fl: Bool = false;
    return (r.value, fl);
  };
  var ok: Bool = true;
  (a + b, ok)
}

/// a - b, returning (wrapped_value, overflowed). Complexity: O(1).
pub fn overflowing_sub(a: Int, b: Int) -> (Int, Bool) {
  var r = num.i64_sub_checked(a, b);
  if r.is_some {
    var fl: Bool = false;
    return (r.value, fl);
  };
  var ok: Bool = true;
  (a - b, ok)
}

/// a * b, returning (wrapped_value, overflowed). Complexity: O(1).
pub fn overflowing_mul(a: Int, b: Int) -> (Int, Bool) {
  var r = num.i64_mul_checked(a, b);
  if r.is_some {
    var fl: Bool = false;
    return (r.value, fl);
  };
  var ok: Bool = true;
  (a * b, ok)
}

/// -a, returning (wrapped_value, overflowed). INT_MIN negates to itself.
/// Complexity: O(1).
pub fn overflowing_neg(a: Int) -> (Int, Bool) {
  if a == INT_MIN {
    var ok: Bool = true;
    return (a, ok);
  };
  var fl: Bool = false;
  (-a, fl)
}
