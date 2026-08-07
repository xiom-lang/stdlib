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
use xiom.string.str_slice;
use xiom.string.str_concat;

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

extern "C" {
  fn xiom_popcnt64(x: Int64) -> Int64;
  fn xiom_clz64(x: Int64) -> Int64;
  fn xiom_ctz64(x: Int64) -> Int64;
}

pub fn count_ones(n: Int) -> Int {
  // Hardware popcount (POPCNT instruction / __builtin_popcountll).
  // The runtime falls back to a SWAR bit-count when unsupported.
  xiom_popcnt64(n)
}

pub fn count_zeros(n: Int) -> Int {
  return size_of[Int]() * 8 - count_ones(n);
}

pub fn leading_zeros(n: Int) -> Int {
  // Hardware LZCNT/BSR (__builtin_clzll). 64 for zero.
  xiom_clz64(n)
}

pub fn trailing_zeros(n: Int) -> Int {
  // Hardware TZCNT/BSF (__builtin_ctzll). 64 for zero.
  xiom_ctz64(n)
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

// ── Basic Integer Predicates ────────────────────────────────────────────────

/// Returns true if n is even. O(1).
pub fn is_even(n: Int) -> Bool {
  n % 2 == 0
}

/// Returns true if n is odd. O(1).
pub fn is_odd(n: Int) -> Bool {
  !(n % 2 == 0)
}

/// Returns true if n > 0. O(1).
pub fn is_positive(n: Int) -> Bool {
  n > 0
}

/// Returns true if n < 0. O(1).
pub fn is_negative(n: Int) -> Bool {
  n < 0
}

/// Returns true if n >= 0. O(1).
pub fn is_non_negative(n: Int) -> Bool {
  n >= 0
}

/// Returns -1 for negative, 0 for zero, 1 for positive. O(1).
pub fn signum(n: Int) -> Int {
  if n > 0 { 1 }
  elif n < 0 { -1 }
  else { 0 }
}

// ── Digit Operations ────────────────────────────────────────────────────────

/// Counts the number of decimal digits. O(log₁₀ n).
pub fn digit_count(n: Int) -> Int {
  if n == 0 { return 1; }
  var count = 0;
  var x = n;
  if x < 0 { x = -x; }
  while x > 0 {
    count = count + 1;
    x = x / 10;
  }
  count
}

/// Sum of decimal digits. O(log₁₀ n).
pub fn digit_sum(n: Int) -> Int {
  var sum = 0;
  var x = n;
  if x < 0 { x = -x; }
  while x > 0 {
    sum = sum + x % 10;
    x = x / 10;
  }
  sum
}

/// Digital root: repeated digit sum until a single digit is obtained. O(log₁₀ n).
pub fn digital_root(n: Int) -> Int {
  if n == 0 { return 0; }
  var r = n % 9;
  if r == 0 { return 9; }
  if r < 0 { return -r; }
  r
}

// ── Combinatorics ───────────────────────────────────────────────────────────

/// Factorial of n (n!). Returns 0 on overflow or negative input. O(N).
pub fn factorial(n: Int) -> Int {
  if n < 0 { return 0; }
  if n <= 1 { return 1; }
  var result = 1;
  var i = 2;
  while i <= n {
    if result > INT_MAX / i { return 0; }
    result = result * i;
    i = i + 1;
  }
  result
}

/// Binomial coefficient C(n, k). Returns 0 on overflow or invalid input. O(k).
pub fn binomial(n: Int, k: Int) -> Int {
  if k < 0 || k > n { return 0; }
  if k == 0 || k == n { return 1; }
  var kk = k;
  if kk > n - kk { kk = n - kk; }
  var result = 1;
  var i = 1;
  while i <= kk {
    if result > INT_MAX / (n - i + 1) { return 0; }
    result = result * (n - i + 1);
    result = result / i;
    i = i + 1;
  }
  result
}

/// Fibonacci number F(n). 0-indexed: F(0)=0, F(1)=1. Returns 0 for n < 0. O(N).
pub fn fibonacci(n: Int) -> Int {
  if n < 0 { return 0; }
  if n <= 1 { return n; }
  var a = 0;
  var b = 1;
  var i = 2;
  while i <= n {
    var c = a + b;
    a = b;
    b = c;
    i = i + 1;
  }
  b
}

// ── Extended GCD / LCM ──────────────────────────────────────────────────────

/// GCD of a slice of integers. Returns 0 if the slice is empty. O(N·log max).
pub fn gcd_many(nums: &Vec[Int]) -> Int {
  var n = nums.len();
  if n == 0 { return 0; }
  var g = nums[0];
  if g < 0 { g = -g; }
  var i = 1;
  while i < n {
    g = gcd(g, nums[i]);
    i = i + 1;
  }
  g
}

/// LCM of a slice of integers. Returns 0 if any element is 0. O(N·log max).
pub fn lcm_many(nums: &Vec[Int]) -> Int {
  var n = nums.len();
  if n == 0 { return 0; }
  var l = nums[0];
  if l < 0 { l = -l; }
  if l == 0 { return 0; }
  var i = 1;
  while i < n {
    l = lcm(l, nums[i]);
    if l == 0 { return 0; }
    i = i + 1;
  }
  l
}

// ── Prime Numbers ───────────────────────────────────────────────────────────

/// Trial-division primality test. O(√n).
pub fn is_prime(n: Int) -> Bool {
  if n < 2 { return false; }
  if n == 2 { return true; }
  if n % 2 == 0 { return false; }
  var i = 3;
  while i * i <= n {
    if n % i == 0 { return false; }
    i = i + 2;
  }
  true
}

/// Next prime greater than n. O(√result · gap).
pub fn next_prime(n: Int) -> Int {
  if n < 2 { return 2; }
  var cand = n + 1;
  if cand % 2 == 0 { cand = cand + 1; }
  while !(is_prime(cand)) {
    cand = cand + 2;
  }
  cand
}

/// Nth prime (1-indexed: nth_prime(1)=2). Returns 0 for n <= 0. O(n·√pₙ).
pub fn nth_prime(n: Int) -> Int {
  if n <= 0 { return 0; }
  if n == 1 { return 2; }
  var count = 1;
  var cand = 3;
  while count < n {
    if is_prime(cand) { count = count + 1; }
    if count < n { cand = cand + 2; }
  }
  cand
}

/// Prime factors of n (with multiplicity). O(√n).
pub fn prime_factors(n: Int) -> Vec[Int] {
  var result = Vec[Int].new();
  if n <= 1 { return result; }
  var x = n;
  if x < 0 { x = -x; }
  while x % 2 == 0 {
    result.push(2);
    x = x / 2;
  }
  var p = 3;
  while p * p <= x {
    while x % p == 0 {
      result.push(p);
      x = x / p;
    }
    p = p + 2;
  }
  if x > 1 { result.push(x); }
  result
}

/// All positive divisors of n (unsorted). O(√n).
pub fn divisors(n: Int) -> Vec[Int] {
  var result = Vec[Int].new();
  if n <= 0 { return result; }
  var x = n;
  if x < 0 { x = -x; }
  var i = 1;
  while i * i <= x {
    if x % i == 0 {
      result.push(i);
      if i != x / i { result.push(x / i); }
    }
    i = i + 1;
  }
  result
}

/// Euler's totient φ(n): count of k in [1, n] with gcd(k, n) = 1. O(√n).
pub fn euler_totient(n: Int) -> Int {
  if n <= 0 { return 0; }
  if n == 1 { return 1; }
  var result = n;
  var temp = n;
  var p = 2;
  while p * p <= temp {
    if temp % p == 0 {
      while temp % p == 0 { temp = temp / p; }
      result = result / p * (p - 1);
    }
    p = p + 1;
  }
  if temp > 1 {
    result = result / temp * (temp - 1);
  }
  result
}

// ── Modular Arithmetic ──────────────────────────────────────────────────────

/// Modular exponentiation: (base^exp) mod m. Uses square-and-multiply. O(log exp).
pub fn mod_pow(base: Int, exp: Int, m: Int) -> Int {
  if m == 1 { return 0; }
  if exp < 0 { return 0; }
  var result = 1;
  var b = base % m;
  if b < 0 { b = b + m; }
  var e = exp;
  while e > 0 {
    if e % 2 == 1 {
      result = (result * b) % m;
    }
    b = (b * b) % m;
    e = e / 2;
  }
  if result < 0 { result = result + m; }
  result
}

/// Modular inverse: x such that (a * x) ≡ 1 (mod m). Uses extended Euclid. O(log min(a,m)).
/// Returns None if gcd(a, m) != 1.
pub fn mod_inverse(a: Int, m: Int) -> Option[Int] {
  var old_r = a % m;
  if old_r < 0 { old_r = old_r + m; }
  var r = m;
  var old_s = 1;
  var s = 0;
  while r != 0 {
    var q = old_r / r;
    var new_r = old_r - q * r;
    var new_s = old_s - q * s;
    old_r = r;
    r = new_r;
    old_s = s;
    s = new_s;
  }
  if !(old_r == 1) { return None; }
  var result = old_s % m;
  if result < 0 { result = result + m; }
  Some(result)
}

/// Modular addition: (a + b) mod m. Result in [0, m). O(1).
pub fn mod_add(a: Int, b: Int, m: Int) -> Int {
  var x = a % m;
  if x < 0 { x = x + m; }
  var y = b % m;
  if y < 0 { y = y + m; }
  var r = (x + y) % m;
  if r < 0 { r = r + m; }
  r
}

/// Modular subtraction: (a - b) mod m. Result in [0, m). O(1).
pub fn mod_sub(a: Int, b: Int, m: Int) -> Int {
  var x = a % m;
  if x < 0 { x = x + m; }
  var y = b % m;
  if y < 0 { y = y + m; }
  var r = (x - y) % m;
  if r < 0 { r = r + m; }
  r
}

/// Modular multiplication: (a * b) mod m. Result in [0, m). O(1).
pub fn mod_mul(a: Int, b: Int, m: Int) -> Int {
  var x = a % m;
  if x < 0 { x = x + m; }
  var y = b % m;
  if y < 0 { y = y + m; }
  var r = (x * y) % m;
  if r < 0 { r = r + m; }
  r
}

// ── Integer Properties ──────────────────────────────────────────────────────

/// Returns true if n is a perfect square. O(log n).
pub fn is_perfect_square(n: Int) -> Bool {
  if n < 0 { return false; }
  if n <= 1 { return true; }
  var lo = 1;
  var hi = n;
  while lo <= hi {
    var mid = lo + (hi - lo) / 2;
    var sq = mid * mid;
    if sq == n { return true; }
    if sq < n { lo = mid + 1; }
    else { hi = mid - 1; }
  }
  false
}

/// Returns true if n reads the same forward and backward in decimal. O(log₁₀ n).
pub fn is_palindrome_int(n: Int) -> Bool {
  if n < 0 { return false; }
  var reversed = 0;
  var x = n;
  while x > 0 {
    reversed = reversed * 10 + x % 10;
    x = x / 10;
  }
  reversed == n
}

/// Reverses the decimal digits of n. Sign is preserved. O(log₁₀ n).
pub fn reverse_int(n: Int) -> Int {
  var neg = n < 0;
  var x = n;
  if neg { x = -x; }
  var rev = 0;
  while x > 0 {
    rev = rev * 10 + x % 10;
    x = x / 10;
  }
  if neg { -rev } else { rev }
}

// ── Base Conversion ─────────────────────────────────────────────────────────

/// Convert integer to string in given base (2–36). Uses digits 0–9, A–Z.
/// Returns empty string for invalid base. O(log_base n).
pub fn to_base(n: Int, base: Int) -> Str {
  if base < 2 || base > 36 { return ""; }
  if n == 0 { return "0"; }
  var neg = false;
  var num = n;
  if num < 0 { neg = true; num = -num; }
  var digits = Vec[Int].new();
  var chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  while num > 0 {
    digits.push(num % base);
    num = num / base;
  }
  var result = "";
  if neg { result = "-"; }
  var i = digits.len() - 1;
  while i >= 0 {
    var d = digits[i];
    var ch = str_slice(chars, d, d + 1);
    result = str_concat(result, ch);
    i = i - 1;
  }
  result
}

/// Parse integer from string in given base (2–36). Delegates to parse_int_radix.
/// Returns None on invalid input or overflow. O(N).
pub fn from_base(s: Str, base: Int) -> Option[Int] {
  if s.len() == 0 { return None; }
  var res = parse_int_radix(s, base);
  match res {
    Ok(v) => Some(v),
    Err(_) => None,
  }
}
