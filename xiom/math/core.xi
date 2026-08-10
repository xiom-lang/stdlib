// XIOM â€” math/core.xi â€” GENERIC numeric tower (3c, 2026-08-10)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// D4 category module: math/core. The flat math.xi keeps the frozen concrete
// contract (math.sqrt(Float64) etc.) as freeze-gated shims; THIS module hosts
// the GENERIC implementations that serve every width through the Num
// interface (impl Num[Int], Num[Int32], Num[Float64], Num[Float32], ...).
// One implementation per concept â€” no per-width duplication.

module xiom.math.core

// â”€â”€ Num interface (the numeric tower contract) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Implemented by every numeric width. New widths register by adding one
// `impl Num[Width] { ... }` block â€” every generic function below then serves
// that width automatically.
pub interface Num[T] {
  fn add(a: T, b: T) -> T;
  fn sub(a: T, b: T) -> T;
  fn mul(a: T, b: T) -> T;
  fn div(a: T, b: T) -> T;
  fn zero() -> T;
  fn one() -> T;
}

// â”€â”€ Width implementations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€ Generic numeric functions (one impl, all widths) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
