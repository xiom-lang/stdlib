// XIOM — Numeric Traits & Operations
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.num

use xiom.math.bit_and;
use xiom.math.bit_or;
use xiom.math.bit_xor;
use xiom.math.bit_not;
use xiom.math.shl;
use xiom.math.shr;
use xiom.math.sqrt;
use xiom.math.is_nan;
use xiom.math.is_inf;
use xiom.core.size_of;
use xiom.core.to_int;
use xiom.core.to_float;
use xiom.core.to_int_from_str;
use xiom.core.to_float_from_str;
use xiom.core.to_int_from_char;
use xiom.core.INT_MAX;
use xiom.core.INT_MIN;
use xiom.string.char_at;

// Extended numeric traits (Add/Sub/Mul/Div are in core)
pub interface Neg { fn neg(self) -> Self; }
pub interface Rem { fn rem(self, other: Self) -> Self; }
pub interface Abs { fn abs(self) -> Self; }
pub interface Pow { fn pow(self, exp: Self) -> Self; }
pub interface Sqrt { fn sqrt(self) -> Self; }

// Numeric bounds
pub interface Bounded {
  fn min_value() -> Self;
  fn max_value() -> Self;
  fn epsilon() -> Self;
  fn zero() -> Self;
}

pub fn min_value[T: Bounded]() -> T {
  return T.min_value();
}

pub fn max_value[T: Bounded]() -> T {
  return T.max_value();
}

pub fn epsilon[T: Bounded]() -> T {
  return T.epsilon();
}

// Integer-specific
pub fn gcd(a: Int, b: Int) -> Int
  ensures: result >= 0
  ensures: a == 0 && b == 0 => result == 0
{
  if b == 0 { return a; }
  return gcd(b, a % b);
}

pub fn lcm(a: Int, b: Int) -> Int {
  if a == 0 || b == 0 { return 0; }
  return a / gcd(a, b) * b;
}

pub fn is_power_of_two(n: Int) -> Bool {
  return n > 0 && bit_and(n, n - 1) == 0;
}

pub fn next_power_of_two(n: Int) -> Int {
  if n <= 0 { return 1; }
  var p = 1;
  while p > 0 && p < n {
    p = shl(p, 1);
  }
  return p;
}

pub fn count_ones(n: Int) -> Int {
  var count = 0;
  var x = n;
  var bits = size_of[Int]() * 8;
  var i = 0;
  while i < bits {
    count = count + bit_and(x, 1);
    x = shr(x, 1);
    i = i + 1;
  }
  return count;
}

pub fn count_zeros(n: Int) -> Int {
  return size_of[Int]() * 8 - count_ones(n);
}

pub fn leading_zeros(n: Int) -> Int {
  if n == 0 { return size_of[Int]() * 8; }
  var count = 0;
  var mask = shl(1, size_of[Int]() * 8 - 1);
  while bit_and(n, mask) == 0 {
    count = count + 1;
    mask = shr(mask, 1);
  }
  return count;
}

pub fn trailing_zeros(n: Int) -> Int {
  if n == 0 { return size_of[Int]() * 8; }
  var count = 0;
  var x = n;
  while bit_and(x, 1) == 0 {
    count = count + 1;
    x = shr(x, 1);
  }
  return count;
}

pub fn rotate_left(n: Int, k: Int) -> Int {
  var bits = size_of[Int]() * 8;
  var shift = k % bits;
  if shift == 0 { return n; }
  return bit_or(shl(n, shift), shr(n, bits - shift));
}

pub fn rotate_right(n: Int, k: Int) -> Int {
  var bits = size_of[Int]() * 8;
  var shift = k % bits;
  if shift == 0 { return n; }
  return bit_or(shr(n, shift), shl(n, bits - shift));
}

pub fn reverse_bits(n: Int) -> Int {
  var result = 0;
  var x = n;
  var bits = size_of[Int]() * 8;
  var i = 0;
  while i < bits {
    result = bit_or(shl(result, 1), bit_and(x, 1));
    x = shr(x, 1);
    i = i + 1;
  }
  return result;
}

pub fn to_be(n: Int) -> Int {
  var result = 0;
  var x = n;
  var bytes = size_of[Int]();
  var i = 0;
  while i < bytes {
    var byte_val = bit_and(x, 255);
    result = bit_or(shl(result, 8), byte_val);
    x = shr(x, 8);
    i = i + 1;
  }
  return result;
}

pub fn to_le(n: Int) -> Int {
  return n;
}

pub fn from_be(n: Int) -> Int {
  return to_be(n);
}

pub fn from_le(n: Int) -> Int {
  return n;
}

// Float-specific
pub fn is_finite(x: Float64) -> Bool {
  var not_nan = !(is_nan(x));
  var not_inf = !(is_inf(x));
  return not_nan && not_inf;
}

pub fn is_normal(x: Float64) -> Bool {
  if x == 0.0 || is_nan(x) || is_inf(x) { return false; }
  return true;
}

pub fn classify(x: Float64) -> Int {
  if is_nan(x) { return 0; }
  if is_inf(x) { return 1; }
  if x == 0.0 { return 2; }
  return 4;
}

pub fn floor(x: Float64) -> Int
  ensures: to_float(result) <= x && x < to_float(result) + 1.0
{
  var i = to_int(x);
  if x >= 0.0 { return i; }
  if to_float(i) == x { return i; }
  return i - 1;
}

pub fn ceil(x: Float64) -> Int
  ensures: to_float(result) - 1.0 < x && x <= to_float(result)
{
  var i = to_int(x);
  if x <= 0.0 { return i; }
  if to_float(i) == x { return i; }
  return i + 1;
}

pub fn round(x: Float64) -> Int {
  if x >= 0.0 { return to_int(x + 0.5); }
  return to_int(x - 0.5);
}

pub fn trunc(x: Float64) -> Int {
  return to_int(x);
}

pub fn fract(x: Float64) -> Float64 {
  return x - to_float(to_int(x));
}

pub fn recip(x: Float64) -> Float64
  requires: x != 0.0
{
  return 1.0 / x;
}

pub fn to_degrees(rad: Float64) -> Float64 {
  return rad * 180.0 / 3.141592653589793;
}

pub fn to_radians(deg: Float64) -> Float64 {
  return deg * 3.141592653589793 / 180.0;
}

pub fn hypot(x: Float64, y: Float64) -> Float64 {
  return sqrt(x * x + y * y);
}

// Saturation arithmetic
pub fn saturating_add[T: Bounded + Ord + Add](a: T, b: T) -> T {
  var z = T.zero();
  var max_val = T.max_value();
  var min_val = T.min_value();
  if b > z && a > max_val - b { return max_val; }
  if b < z && a < min_val - b { return min_val; }
  return a + b;
}

pub fn saturating_sub[T: Bounded + Ord + Sub](a: T, b: T) -> T {
  var z = T.zero();
  var max_val = T.max_value();
  var min_val = T.min_value();
  if b < z && a > max_val + b { return max_val; }
  if b > z && a < min_val + b { return min_val; }
  return a - b;
}

pub fn saturating_mul[T: Bounded + Ord + Mul + Div](a: T, b: T) -> T {
  var z = T.zero();
  if a == z || b == z { return z; }
  var max_val = T.max_value();
  var min_val = T.min_value();
  if a > z && b > z && a > max_val / b { return max_val; }
  if a > z && b < z && b < min_val / a { return min_val; }
  if a < z && b > z && a < min_val / b { return min_val; }
  if a < z && b < z && a < max_val / b { return max_val; }
  return a * b;
}

// Checked arithmetic
pub fn checked_add[T: Bounded + Ord + Add](a: T, b: T) -> Option[T] {
  var z = T.zero();
  var max_val = T.max_value();
  var min_val = T.min_value();
  if b > z && a > max_val - b { return None; }
  if b < z && a < min_val - b { return None; }
  return Some(a + b);
}

pub fn checked_sub[T: Bounded + Ord + Sub](a: T, b: T) -> Option[T] {
  var z = T.zero();
  var max_val = T.max_value();
  var min_val = T.min_value();
  if b < z && a > max_val + b { return None; }
  if b > z && a < min_val + b { return None; }
  return Some(a - b);
}

pub fn checked_mul[T: Bounded + Ord + Mul + Div](a: T, b: T) -> Option[T] {
  var z = T.zero();
  if a == z || b == z { return Some(z); }
  var max_val = T.max_value();
  var min_val = T.min_value();
  if a > z && b > z && a > max_val / b { return None; }
  if a > z && b < z && b < min_val / a { return None; }
  if a < z && b > z && a < min_val / b { return None; }
  if a < z && b < z && a < max_val / b { return None; }
  return Some(a * b);
}

pub fn checked_div[T: Bounded + Eq + Div](a: T, b: T) -> Option[T]
  ensures: b == zero() => result is None
{
  var z = T.zero();
  if b == z { return None; }
  return Some(a / b);
}

// Wrapping arithmetic
pub fn wrapping_add[T: Bounded + Add](a: T, b: T) -> T {
  return a + b;
}

pub fn wrapping_sub[T: Bounded + Sub](a: T, b: T) -> T {
  return a - b;
}

pub fn wrapping_mul[T: Bounded + Mul](a: T, b: T) -> T {
  return a * b;
}

// Parse
pub fn parse_int(s: Str) -> Result[Int, Str] {
  return to_int_from_str(s);
}

pub fn parse_float(s: Str) -> Result[Float64, Str] {
  return to_float_from_str(s);
}

pub fn parse_int_radix(s: Str, radix: Int) -> Result[Int, Str]
  requires: s.len() > 0
  requires: 2 <= radix && radix <= 36
{
  if radix < 2 || radix > 36 { return Err("invalid radix"); }
  if s.len() == 0 { return Err("empty string"); }
  var result = 0;
  var neg = false;
  var i = 0;
  var opt = char_at(s, 0);
  if opt.is_some {
    var first = opt.value;
    if first == '-' {
      neg = true;
      i = 1;
    } elif first == '+' {
      i = 1;
    }
  }
  while i < s.len() {
    opt = char_at(s, i);
    if !(opt.is_some) { return Err("invalid index"); }
    var c = opt.value;
    var digit = -1;
    if c >= '0' && c <= '9' { digit = to_int_from_char(c) - to_int_from_char('0'); }
    elif c >= 'a' && c <= 'z' { digit = to_int_from_char(c) - to_int_from_char('a') + 10; }
    elif c >= 'A' && c <= 'Z' { digit = to_int_from_char(c) - to_int_from_char('A') + 10; }
    if digit < 0 || digit >= radix { return Err("invalid digit"); }
    if result > (INT_MAX - digit) / radix { return Err("overflow"); }
    result = result * radix + digit;
    i = i + 1;
  }
  if neg { return Ok(-result); }
  return Ok(result);
}
