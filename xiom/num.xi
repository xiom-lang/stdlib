// XIOM — Numeric Traits & Operations
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.num

// Extended numeric traits (Add/Sub/Mul/Div are in core)
pub interface Neg { fn neg(self) -> Self; }
pub interface Rem { fn rem(self, other: Self) -> Self; }
pub interface Abs { fn abs(self) -> Self; }
pub interface Pow { fn pow(self, exp: Self) -> Self; }
pub interface Sqrt { fn sqrt(self) -> Self; }

// Numeric bounds
pub fn min_value[T]() -> T;
pub fn max_value[T]() -> T;
pub fn epsilon[T]() -> T;

// Integer-specific
pub fn gcd(a: Int, b: Int) -> Int;
pub fn lcm(a: Int, b: Int) -> Int;
pub fn is_power_of_two(n: Int) -> Bool;
pub fn next_power_of_two(n: Int) -> Int;
pub fn count_ones(n: Int) -> Int;
pub fn count_zeros(n: Int) -> Int;
pub fn leading_zeros(n: Int) -> Int;
pub fn trailing_zeros(n: Int) -> Int;
pub fn rotate_left(n: Int, k: Int) -> Int;
pub fn rotate_right(n: Int, k: Int) -> Int;
pub fn reverse_bits(n: Int) -> Int;
pub fn to_be(n: Int) -> Int;
pub fn to_le(n: Int) -> Int;
pub fn from_be(n: Int) -> Int;
pub fn from_le(n: Int) -> Int;

// Float-specific
pub fn is_finite(x: Float64) -> Bool;
pub fn is_normal(x: Float64) -> Bool;
pub fn classify(x: Float64) -> Int; // 0=nan, 1=infinite, 2=zero, 3=subnormal, 4=normal
pub fn floor(x: Float64) -> Int;
pub fn ceil(x: Float64) -> Int;
pub fn round(x: Float64) -> Int;
pub fn trunc(x: Float64) -> Int;
pub fn fract(x: Float64) -> Float64;
pub fn recip(x: Float64) -> Float64;
pub fn to_degrees(rad: Float64) -> Float64;
pub fn to_radians(deg: Float64) -> Float64;
pub fn hypot(x: Float64, y: Float64) -> Float64;

// Saturation arithmetic
pub fn saturating_add[T](a: T, b: T) -> T;
pub fn saturating_sub[T](a: T, b: T) -> T;
pub fn saturating_mul[T](a: T, b: T) -> T;

// Checked arithmetic
pub fn checked_add[T](a: T, b: T) -> Option[T];
pub fn checked_sub[T](a: T, b: T) -> Option[T];
pub fn checked_mul[T](a: T, b: T) -> Option[T];
pub fn checked_div[T](a: T, b: T) -> Option[T];

// Wrapping arithmetic
pub fn wrapping_add[T](a: T, b: T) -> T;
pub fn wrapping_sub[T](a: T, b: T) -> T;
pub fn wrapping_mul[T](a: T, b: T) -> T;

// Parse
pub fn parse_int(s: Str) -> Result[Int, Str];
pub fn parse_float(s: Str) -> Result[Float64, Str];
pub fn parse_int_radix(s: Str, radix: Int) -> Result[Int, Str];
