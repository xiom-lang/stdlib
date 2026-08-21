// XIOM - math/core.xi - GENERIC numeric tower (3c, 2026-08-10)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// D4 category module: math/core. The flat math.xi keeps the frozen concrete
// contract (math.sqrt(Float64) etc.) as freeze-gated shims; THIS module hosts
// the GENERIC implementations that serve every width through the Num
// interface (impl Num[Int], Num[Int32], Num[Float64], Num[Float32], ...).
// One implementation per concept - no per-width duplication.

module xiom.math.tower

// The generic numeric tower contract (Num/Real/FromInt) -- the name `tower`
// (renamed from `core` 2026-08-11, owner decision) distinguishes it from the
// prelude `xiom.core`. STDLIB_GENERICS.md rule R9: no other sublib may be
// named `core`; the prelude owns that name.

// -- Num interface (the numeric tower contract) ------------------------------
// Implemented by every numeric width. New widths register by adding one
// `impl Num[Width] { ... }` block - every generic function below then serves
// that width automatically.
pub interface Num[T] {
  fn add(a: T, b: T) -> T;
  fn sub(a: T, b: T) -> T;
  fn mul(a: T, b: T) -> T;
  fn div(a: T, b: T) -> T;
  fn zero() -> T;
  fn one() -> T;
}

// -- Width implementations ----------------------------------------------------

impl Num[Int] {
  fn add(a: Int, b: Int) -> Int { return a + b; }
  fn sub(a: Int, b: Int) -> Int { return a - b; }
  fn mul(a: Int, b: Int) -> Int { return a * b; }
  fn div(a: Int, b: Int) -> Int { return a / b; }
  fn zero() -> Int { return 0; }
  fn one() -> Int { return 1; }
  fn from_int(v: Int) -> Int { return v; }
  fn to_float(v: Int) -> Float64 { return v as Float64; }
}

impl Num[Int32] {
  fn add(a: Int32, b: Int32) -> Int32 { return a + b; }
  fn sub(a: Int32, b: Int32) -> Int32 { return a - b; }
  fn mul(a: Int32, b: Int32) -> Int32 { return a * b; }
  fn div(a: Int32, b: Int32) -> Int32 { return a / b; }
  fn zero() -> Int32 { return 0 as Int32; }
  fn one() -> Int32 { return 1 as Int32; }
  fn from_int(v: Int) -> Int32 { return v as Int32; }
  fn to_float(v: Int32) -> Float64 { return v as Float64; }
}

impl Num[Int64] {
  fn add(a: Int64, b: Int64) -> Int64 { return a + b; }
  fn sub(a: Int64, b: Int64) -> Int64 { return a - b; }
  fn mul(a: Int64, b: Int64) -> Int64 { return a * b; }
  fn div(a: Int64, b: Int64) -> Int64 { return a / b; }
  fn zero() -> Int64 { return 0 as Int64; }
  fn one() -> Int64 { return 1 as Int64; }
  fn from_int(v: Int) -> Int64 { return v as Int64; }
  fn to_float(v: Int64) -> Float64 { return v as Float64; }
}

impl Num[UInt64] {
  fn add(a: UInt64, b: UInt64) -> UInt64 { return a + b; }
  fn sub(a: UInt64, b: UInt64) -> UInt64 { return a - b; }
  fn mul(a: UInt64, b: UInt64) -> UInt64 { return a * b; }
  fn div(a: UInt64, b: UInt64) -> UInt64 { return a / b; }
  fn zero() -> UInt64 { return 0 as UInt64; }
  fn one() -> UInt64 { return 1 as UInt64; }
  fn from_int(v: Int) -> UInt64 { return v as UInt64; }
  fn to_float(v: UInt64) -> Float64 { return v as Float64; }
}

impl Num[Float64] {
  fn add(a: Float64, b: Float64) -> Float64 { return a + b; }
  fn sub(a: Float64, b: Float64) -> Float64 { return a - b; }
  fn mul(a: Float64, b: Float64) -> Float64 { return a * b; }
  fn div(a: Float64, b: Float64) -> Float64 { return a / b; }
  fn zero() -> Float64 { return 0.0; }
  fn one() -> Float64 { return 1.0; }
  fn from_int(v: Int) -> Float64 { return v as Float64; }
  fn to_float(v: Float64) -> Float64 { return v; }
}

impl Num[Float32] {
  fn add(a: Float32, b: Float32) -> Float32 { return a + b; }
  fn sub(a: Float32, b: Float32) -> Float32 { return a - b; }
  fn mul(a: Float32, b: Float32) -> Float32 { return a * b; }
  fn div(a: Float32, b: Float32) -> Float32 { return a / b; }
  fn zero() -> Float32 { return 0 as Float32; }
  fn one() -> Float32 { return 1 as Float32; }
  fn from_int(v: Int) -> Float32 { return v as Float32; }
  fn to_float(v: Float32) -> Float64 { return v as Float64; }
}

// -- Generic numeric functions (one impl, all widths) -----------------------

/// Linear interpolation: a*(1-t) + b*t. Generic over every Num width.
pub fn lerp[T: Num](a: T, b: T, t: T) -> T {
  var one = Num[T].one();
  var omt = Num[T].sub(one, t);
  return Num[T].add(Num[T].mul(a, omt), Num[T].mul(b, t));
}

/// Arithmetic mean of two values. Generic over every Num width.
pub fn average[T: Num](a: T, b: T) -> T {
  var sum = Num[T].add(a, b);
  var one = Num[T].one();
  var two = Num[T].add(one, one);
  return Num[T].div(sum, two);
}

/// Sum of a Vec of values. Generic over every Num width.
pub fn sum[T: Num](values: Vec[T]) -> T {
  var total = Num[T].zero();
  var i = 0;
  while i < values.len() {
    total = Num[T].add(total, values[i]);
    i = i + 1;
  }
  return total;
}

/// Product of a Vec of values. Generic over every Num width.
pub fn product[T: Num](values: Vec[T]) -> T {
  var total = Num[T].one();
  var i = 0;
  while i < values.len() {
    total = Num[T].mul(total, values[i]);
    i = i + 1;
  }
  return total;
}

/// Double a value. Generic over every Num width.
pub fn twice[T: Num](a: T) -> T {
  return Num[T].add(a, a);
}

/// Negate via zero - a. Generic over every Num width.
pub fn negate[T: Num](a: T) -> T {
  return Num[T].sub(Num[T].zero(), a);
}

// -- FromInt interface (conversions ? separate from arithmetic Num) ----------
// Widths opt into Int conversion by implementing FromInt. Keeps Num pure
// arithmetic so the tower contract stays minimal.

pub interface FromInt[T] {
  fn from_int(v: Int) -> T;
  fn to_float(v: T) -> Float64;
}

impl FromInt[Int] {
  fn from_int(v: Int) -> Int { return v; }
  fn to_float(v: Int) -> Float64 { return v as Float64; }
}

impl FromInt[Int32] {
  fn from_int(v: Int) -> Int32 { return v as Int32; }
  fn to_float(v: Int32) -> Float64 { return v as Float64; }
}

impl FromInt[Int64] {
  fn from_int(v: Int) -> Int64 { return v as Int64; }
  fn to_float(v: Int64) -> Float64 { return v as Float64; }
}

impl FromInt[UInt64] {
  fn from_int(v: Int) -> UInt64 { return v as UInt64; }
  fn to_float(v: UInt64) -> Float64 { return v as Float64; }
}

impl FromInt[Float64] {
  fn from_int(v: Int) -> Float64 { return v as Float64; }
  fn to_float(v: Float64) -> Float64 { return v; }
}

impl FromInt[Float32] {
  fn from_int(v: Int) -> Float32 { return v as Float32; }
  fn to_float(v: Float32) -> Float64 { return v as Float64; }
}

// -- Generic conversion + comparison helpers ---------------------------------

// NOTE: generic abs/clamp/sqrt require COMPARISON, which is not part of the
// Num tower (Num is pure arithmetic). The `Real` interface below extends the
// tower with comparison + sign ops so abs/clamp/min/max become generic too.
// Float widths also gain sqrt via their concrete math.sqrt.

pub interface Real[T] {
  fn lt(a: T, b: T) -> Bool;
  fn gt(a: T, b: T) -> Bool;
  fn le(a: T, b: T) -> Bool;
  fn ge(a: T, b: T) -> Bool;
  fn is_negative(a: T) -> Bool;
}

impl Real[Int] {
  fn lt(a: Int, b: Int) -> Bool { return a < b; }
  fn gt(a: Int, b: Int) -> Bool { return a > b; }
  fn le(a: Int, b: Int) -> Bool { return a <= b; }
  fn ge(a: Int, b: Int) -> Bool { return a >= b; }
  fn is_negative(a: Int) -> Bool { return a < 0; }
}

impl Real[Int32] {
  fn lt(a: Int32, b: Int32) -> Bool { return a < b; }
  fn gt(a: Int32, b: Int32) -> Bool { return a > b; }
  fn le(a: Int32, b: Int32) -> Bool { return a <= b; }
  fn ge(a: Int32, b: Int32) -> Bool { return a >= b; }
  fn is_negative(a: Int32) -> Bool { return a < (0 as Int32); }
}

impl Real[Float64] {
  fn lt(a: Float64, b: Float64) -> Bool { return a < b; }
  fn gt(a: Float64, b: Float64) -> Bool { return a > b; }
  fn le(a: Float64, b: Float64) -> Bool { return a <= b; }
  fn ge(a: Float64, b: Float64) -> Bool { return a >= b; }
  fn is_negative(a: Float64) -> Bool { return a < 0.0; }
}

impl Real[Float32] {
  fn lt(a: Float32, b: Float32) -> Bool { return a < b; }
  fn gt(a: Float32, b: Float32) -> Bool { return a > b; }
  fn le(a: Float32, b: Float32) -> Bool { return a <= b; }
  fn ge(a: Float32, b: Float32) -> Bool { return a >= b; }
  fn is_negative(a: Float32) -> Bool { return a < (0 as Float32); }
}

/// Absolute value. Generic over widths implementing Real.
pub fn abs[T: Real + Num](a: T) -> T {
  if Real[T].is_negative(a) {
    return Num[T].sub(Num[T].zero(), a);
  }
  return a;
}

/// Clamp x into [lo, hi]. Generic over widths implementing Real.
pub fn clamp[T: Real + Num](x: T, lo: T, hi: T) -> T {
  if Real[T].lt(x, lo) { return lo; }
  if Real[T].gt(x, hi) { return hi; }
  return x;
}

/// Minimum of two values. Generic over widths implementing Real.
pub fn min2[T: Real](a: T, b: T) -> T {
  if Real[T].lt(a, b) { return a; }
  return b;
}

/// Maximum of two values. Generic over widths implementing Real.
pub fn max2[T: Real](a: T, b: T) -> T {
  if Real[T].gt(a, b) { return a; }
  return b;
}

/// Build a value of any FromInt width from an Int literal.
pub fn of_int[T: FromInt](v: Int) -> T {
  return FromInt[T].from_int(v);
}

// NOTE: generic sqrt needs transcendental support per width ? the Float64
// sqrt is concrete (math.sqrt). A future `Transcendental` interface hosts it.
