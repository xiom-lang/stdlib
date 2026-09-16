// XIOM - Math: Interfaces
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.interfaces

// Depends on: none

// ============================================================================
// Generic numeric interfaces (DECLARE-ONLY per STDLIB_GENERICS R3/R8).
//
// These declarations describe the capabilities the numeric tower exposes for
// every width. Per STDLIB_GENERICS R3/R8 this module declares the interfaces
// and performs no dispatch (no impl blocks); concrete implementations live in
// math/tower.xi (Num/FromInt/Real) and the width-specific modules. The
// generic method names here follow the tower convention so that a future
// generic engine can bind them without renaming.
// ============================================================================

// Numeric arithmetic contract: add/sub/mul/div plus the identity elements.
pub interface Numeric {
  fn add(a: Self, b: Self) -> Self;
  fn sub(a: Self, b: Self) -> Self;
  fn mul(a: Self, b: Self) -> Self;
  fn div(a: Self, b: Self) -> Self;
  fn abs(a: Self) -> Self;
  fn neg(a: Self) -> Self;
  fn signum(a: Self) -> Int;
  fn zero() -> Self;
  fn one() -> Self;
}

// Integer arithmetic contract: division with remainder and quotient plus
// Int construction.
pub interface Integer {
  fn add(a: Self, b: Self) -> Self;
  fn sub(a: Self, b: Self) -> Self;
  fn mul(a: Self, b: Self) -> Self;
  fn div(a: Self, b: Self) -> Self;
  fn rem(a: Self, b: Self) -> Self;
  fn quot(a: Self, b: Self) -> Self;
  fn abs(a: Self) -> Self;
  fn neg(a: Self) -> Self;
  fn zero() -> Self;
  fn one() -> Self;
  fn from_int(v: Int) -> Self;
}

// Signed arithmetic contract: add/sub/mul/div with sign operations.
pub interface Signed {
  fn add(a: Self, b: Self) -> Self;
  fn sub(a: Self, b: Self) -> Self;
  fn mul(a: Self, b: Self) -> Self;
  fn div(a: Self, b: Self) -> Self;
  fn abs(a: Self) -> Self;
  fn neg(a: Self) -> Self;
  fn signum(a: Self) -> Int;
  fn zero() -> Self;
  fn one() -> Self;
}

// Unsigned arithmetic contract: no negation, remainder and quotient only.
pub interface Unsigned {
  fn add(a: Self, b: Self) -> Self;
  fn sub(a: Self, b: Self) -> Self;
  fn mul(a: Self, b: Self) -> Self;
  fn div(a: Self, b: Self) -> Self;
  fn rem(a: Self, b: Self) -> Self;
  fn quot(a: Self, b: Self) -> Self;
  fn zero() -> Self;
  fn one() -> Self;
  fn from_int(v: Int) -> Self;
}

// Floating-point contract: arithmetic plus the IEEE rounding family.
pub interface Float {
  fn add(a: Self, b: Self) -> Self;
  fn sub(a: Self, b: Self) -> Self;
  fn mul(a: Self, b: Self) -> Self;
  fn div(a: Self, b: Self) -> Self;
  fn neg(a: Self) -> Self;
  fn abs(a: Self) -> Self;
  fn sqrt(a: Self) -> Self;
  fn floor(a: Self) -> Self;
  fn ceil(a: Self) -> Self;
  fn round(a: Self) -> Self;
  fn trunc(a: Self) -> Self;
  fn zero() -> Self;
  fn one() -> Self;
}

// Total-order comparison contract.
pub interface Ord {
  fn cmp(a: Self, b: Self) -> Int;
  fn lt(a: Self, b: Self) -> Bool;
  fn le(a: Self, b: Self) -> Bool;
  fn gt(a: Self, b: Self) -> Bool;
  fn ge(a: Self, b: Self) -> Bool;
  fn min(a: Self, b: Self) -> Self;
  fn max(a: Self, b: Self) -> Self;
}

// Bounded-value contract: the representable range and finiteness tests.
pub interface Bounded {
  fn min_value() -> Self;
  fn max_value() -> Self;
  fn is_finite(a: Self) -> Bool;
  fn is_infinite(a: Self) -> Bool;
}

// Parse-from-string contract.
pub interface FromStr {
  fn from_str(s: Str) -> Result[Self, Str];
}

// Human-readable rendering contract.
pub interface Display {
  fn to_string(a: Self) -> Str;
}
