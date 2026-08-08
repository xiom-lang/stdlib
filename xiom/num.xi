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
use xiom.string.str_len;
use xiom.core.to_string;
use xiom.math.pow;

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

// ═══════════════════════════════════════════════════════════════════════════
// PRODUCTION NUMERIC TOWER
// ═══════════════════════════════════════════════════════════════════════════
// These functions are intentionally CONCRETE (per-width, non-generic): the
// monomorphiser currently miscompiles generic arithmetic on Float64, so every
// operation below is written against one exact type. Interfaces are declared
// only to document the intended API shape; impl blocks are not relied upon.

// ── 128-bit signed integer ─────────────────────────────────────────────────
// D1 (2026-08-08): Int128 is now a NATIVE compiler primitive (LLVM i128),
// not a hi/lo struct. All arithmetic is hardware (or __divti3/__udivti3
// runtime libcalls), exact for the full 128-bit range. The old struct-based
// implementation was removed with the D1 native primitive landing.

// ── Rational number (num / den, den > 0, always reduced) ───────────────────
pub type Fraction = { num: Int; den: Int; }

// Internal: unsigned 64-bit division result.
pub type U64DivRem = { quot: UInt64; rem: UInt64; }

// Internal: Int128 division by a small scalar.
pub type I128DivRem = { quot: Int128; rem: Int; }

// ── UInt64 core helpers ────────────────────────────────────────────────────
// The compiler emits SIGNED LLVM instructions for UInt64 `%`, `/`, `>>` and
// `>` (verified: 0xFFFFFFFFFFFFFFFF / 2 == 0, not 0x7FFF…). These helpers
// restore correct unsigned semantics using bit tricks and logical shifts.

/// Returns bit `i` (0..63) of an unsigned 64-bit value as 0 or 1.
/// Works because the low bit of an arithmetic shift equals the low bit of a
/// logical shift; the sign fill only affects bits above position 0.
/// Complexity: O(1). Pure.
fn u64_bit(x: UInt64, i: Int) -> Int {
  return ((x >> i) & 1) as Int;
}

/// Three-way unsigned comparison of two UInt64 values: -1, 0 or 1.
/// When the sign bits differ, the operand with the clear high bit is smaller
/// (it lies in [0, 2^63), the other in [2^63, 2^64)); when they agree, the
/// signed i64 comparison of the low 63 bits is correct (both operands were
/// biased by the same constant).
/// Complexity: O(1). Pure.
fn u64_compare(a: UInt64, b: UInt64) -> Int {
  var ah = u64_bit(a, 63);
  var bh = u64_bit(b, 63);
  if ah != bh {
    if ah == 0 { return -1; }
    return 1;
  }
  if (a as Int) < (b as Int) { return -1; }
  if (a as Int) > (b as Int) { return 1; }
  return 0;
}

/// Returns true iff a >= b interpreted as UNSIGNED 64-bit integers.
/// Complexity: O(1). Pure.
fn u64_ge(a: UInt64, b: UInt64) -> Bool {
  var ah = u64_bit(a, 63);
  var bh = u64_bit(b, 63);
  if ah != bh { return ah == 1; }
  return (a as Int) >= (b as Int);
}

/// Logical (unsigned) right shift of a UInt64 by k bits.
/// The builtin `>>` on UInt64 is arithmetic; this masks off the sign fill.
/// Complexity: O(1). Pure.
fn u64_logical_shr(x: UInt64, k: Int) -> UInt64 {
  if k <= 0 { return x; }
  if k >= 64 { var z: UInt64 = 0; return z; }
  var mask: UInt64 = ((1 as UInt64) << (64 - k)) - 1;
  return (x >> k) & mask;
}

/// Unsigned 64/64 division. Requires y != 0 (returns 0/0 otherwise, caller
/// must guard). Binary long division over 64 bits; the partial remainder is
/// tracked with an extra carry bit because `rem << 1` can spill past 64 bits.
/// Complexity: O(64). Pure.
fn u64_div_mod(x: UInt64, y: UInt64) -> U64DivRem {
  if y == 0 {
    return U64DivRem{ quot: 0; rem: 0; };
  }
  var quot: UInt64 = 0;
  var rem: UInt64 = 0;
  var i = 63;
  while i >= 0 {
    var extra = u64_bit(rem, 63);
    rem = (rem << 1) | ((x >> i) & 1);
    var subtract = false;
    if extra == 1 {
      subtract = true;
    } else {
      if u64_ge(rem, y) { subtract = true; }
    }
    if subtract {
      rem = rem - y;
      quot = quot | ((1 as UInt64) << i);
    }
    i = i - 1;
  }
  return U64DivRem{ quot: quot; rem: rem; };
}

/// Full 128-bit unsigned product of two UInt64 values.
/// D1: native — `(x as UInt128) * (y as UInt128)` is exact (LLVM i128 mul).
/// Returns the 128-bit product as Int128 (bit pattern preserved).
/// Complexity: O(1). Pure.
fn u64_mul_wide(x: UInt64, y: UInt64) -> Int128 {
  var xw = x as UInt128;
  var yw = y as UInt128;
  var prod = xw * yw;
  return prod as Int128;
}

/// Magnitude |v| of a signed 64-bit value as UInt64. Correct for INT_MIN
/// (wraps via two's-complement negation). Complexity: O(1). Pure.
fn u64_mag(v: Int) -> UInt64 {
  if v >= 0 { return v as UInt64; }
  var z: UInt64 = 0;
  return z - (v as UInt64);
}

/// Returns the maximum UInt64 value (0xFFFFFFFFFFFFFFFF).
/// Avoids writing a hex literal larger than i64::MAX directly.
/// Complexity: O(1). Pure.
fn u64_max_value() -> UInt64 {
  var m: UInt64 = 0;
  m = m - 1;
  return m;
}

/// Returns the Int128 zero value. D1: native. Complexity: O(1). Pure.
fn i128_zero() -> Int128 {
  return 0 as Int128;
}

// ── Rounding & fractions: Float64 ───────────────────────────────────────────
// All of these return Float64. Values with |x| >= 2^63 are exactly integral
// in IEEE-754 (ULP >= 2^11), so floor/ceil/round/trunc return x and fract
// returns 0 without touching `to_int` (whose behaviour is undefined out of
// the i64 range).

/// Rounds x to the nearest Float64, halves away from zero
/// (round(2.5) == 3.0, round(-2.5) == -3.0). NaN propagates.
/// Complexity: O(1).
pub fn f64_round(x: Float64) -> Float64 {
  if is_nan(x) { return x; }
  if x >= 9223372036854775808.0 || x < -9223372036854775808.0 { return x; }
  if x >= 0.0 { return floor(x + 0.5) as Float64; }
  return ceil(x - 0.5) as Float64;
}

/// Largest integral Float64 <= x. NaN propagates.
/// Complexity: O(1).
pub fn f64_floor(x: Float64) -> Float64 {
  if is_nan(x) { return x; }
  if x >= 9223372036854775808.0 || x < -9223372036854775808.0 { return x; }
  var i = to_int(x);
  if x >= 0.0 { return i as Float64; }
  if (i as Float64) == x { return x; }
  return (i - 1) as Float64;
}

/// Smallest integral Float64 >= x. NaN propagates.
/// Complexity: O(1).
pub fn f64_ceil(x: Float64) -> Float64 {
  if is_nan(x) { return x; }
  if x >= 9223372036854775808.0 || x < -9223372036854775808.0 { return x; }
  var i = to_int(x);
  if x <= 0.0 { return i as Float64; }
  if (i as Float64) == x { return x; }
  return (i + 1) as Float64;
}

/// Truncates x toward zero, returning the integral part as Float64.
/// NaN propagates. Complexity: O(1).
pub fn f64_trunc(x: Float64) -> Float64 {
  if is_nan(x) { return x; }
  if x >= 9223372036854775808.0 || x < -9223372036854775808.0 { return x; }
  return to_int(x) as Float64;
}

/// Fractional part of x with the sign of x: x - trunc(x).
/// fract(2.75) == 0.75, fract(-2.75) == -0.75. NaN propagates.
/// Complexity: O(1).
pub fn f64_fract(x: Float64) -> Float64 {
  if is_nan(x) { return x; }
  if x >= 9223372036854775808.0 || x < -9223372036854775808.0 { return 0.0; }
  return x - to_float(to_int(x));
}

/// Integral part of x (C `modf` split, matches f64_fract's sign convention).
/// Equivalent to f64_trunc. Complexity: O(1).
pub fn f64_modf_int_part(x: Float64) -> Float64 {
  return f64_trunc(x);
}

/// Fractional part of x (C `modf` split, sign of x).
/// Equivalent to f64_fract. Complexity: O(1).
pub fn f64_modf_frac_part(x: Float64) -> Float64 {
  return f64_fract(x);
}

// ── Rounding & fractions: Float32 ───────────────────────────────────────────
// Float32 mirrors Float64; `to_int` accepts Float32 directly, and values with
// |x| >= 2^63 are exactly integral (Float32 ULP there is 2^40).

/// Rounds x to the nearest Float32, halves away from zero. NaN propagates.
/// Complexity: O(1).
pub fn f32_round(x: Float32) -> Float32 {
  var xd = x as Float64;
  if is_nan(xd) { return x; }
  if xd >= 9223372036854775808.0 || xd < -9223372036854775808.0 { return x; }
  if xd >= 0.0 { return floor(xd + 0.5) as Float32; }
  return ceil(xd - 0.5) as Float32;
}

/// Largest integral Float32 <= x. NaN propagates.
/// Complexity: O(1).
pub fn f32_floor(x: Float32) -> Float32 {
  var xd = x as Float64;
  if is_nan(xd) { return x; }
  if xd >= 9223372036854775808.0 || xd < -9223372036854775808.0 { return x; }
  var i = to_int(x);
  if x >= 0.0 { return i as Float32; }
  if ((i as Float64) as Float32) == x { return x; }
  return (i - 1) as Float32;
}

/// Smallest integral Float32 >= x. NaN propagates.
/// Complexity: O(1).
pub fn f32_ceil(x: Float32) -> Float32 {
  var xd = x as Float64;
  if is_nan(xd) { return x; }
  if xd >= 9223372036854775808.0 || xd < -9223372036854775808.0 { return x; }
  var i = to_int(x);
  if x <= 0.0 { return i as Float32; }
  if ((i as Float64) as Float32) == x { return x; }
  return (i + 1) as Float32;
}

/// Truncates x toward zero as Float32. NaN propagates.
/// Complexity: O(1).
pub fn f32_trunc(x: Float32) -> Float32 {
  var xd = x as Float64;
  if is_nan(xd) { return x; }
  if xd >= 9223372036854775808.0 || xd < -9223372036854775808.0 { return x; }
  return to_int(x) as Float32;
}

/// Fractional part of x with the sign of x. NaN propagates.
/// Complexity: O(1).
pub fn f32_fract(x: Float32) -> Float32 {
  var xd = x as Float64;
  if is_nan(xd) { return x; }
  if xd >= 9223372036854775808.0 || xd < -9223372036854775808.0 { return 0.0 as Float32; }
  return (x - (to_int(x) as Float32)) as Float32;
}

/// Integral part of x (C `modf` split). Equivalent to f32_trunc.
/// Complexity: O(1).
pub fn f32_modf_int_part(x: Float32) -> Float32 {
  return f32_trunc(x);
}

/// Fractional part of x (C `modf` split, sign of x).
/// Complexity: O(1).
pub fn f32_modf_frac_part(x: Float32) -> Float32 {
  return f32_fract(x);
}

// ── Float-to-Int rounding (round-half-away-from-zero) ───────────────────────
// Out-of-range and NaN inputs saturate/are documented per function.

/// Rounds x to the nearest Int, halves away from zero. NaN -> 0,
/// out of i64 range -> saturated INT_MAX/INT_MIN. Complexity: O(1).
pub fn f64_round_to_int(x: Float64) -> Int {
  if is_nan(x) { return 0; }
  if x >= 9223372036854775808.0 { return INT_MAX; }
  if x < -9223372036854775808.0 { return INT_MIN; }
  if x >= 0.0 { return to_int(x + 0.5); }
  return to_int(x - 0.5);
}

/// Floor of x as Int. NaN -> 0, out of i64 range -> saturated INT_MAX/INT_MIN.
/// Complexity: O(1).
pub fn f64_floor_to_int(x: Float64) -> Int {
  if is_nan(x) { return 0; }
  if x >= 9223372036854775808.0 { return INT_MAX; }
  if x < -9223372036854775808.0 { return INT_MIN; }
  var i = to_int(x);
  if x >= 0.0 { return i; }
  if (i as Float64) == x { return i; }
  return i - 1;
}

/// Ceiling of x as Int. NaN -> 0, out of i64 range -> saturated INT_MAX/INT_MIN.
/// Complexity: O(1).
pub fn f64_ceil_to_int(x: Float64) -> Int {
  if is_nan(x) { return 0; }
  if x >= 9223372036854775808.0 { return INT_MAX; }
  if x < -9223372036854775808.0 { return INT_MIN; }
  var i = to_int(x);
  if x <= 0.0 { return i; }
  if (i as Float64) == x { return i; }
  return i + 1;
}

/// Truncation of x toward zero as Int. NaN -> 0, out of i64 range ->
/// saturated INT_MAX/INT_MIN. Complexity: O(1).
pub fn f64_trunc_to_int(x: Float64) -> Int {
  if is_nan(x) { return 0; }
  if x >= 9223372036854775808.0 { return INT_MAX; }
  if x < -9223372036854775808.0 { return INT_MIN; }
  return to_int(x);
}

/// Float32 variant of f64_round_to_int. Complexity: O(1).
pub fn f32_round_to_int(x: Float32) -> Int {
  return f64_round_to_int(x as Float64);
}

/// Float32 variant of f64_floor_to_int. Complexity: O(1).
pub fn f32_floor_to_int(x: Float32) -> Int {
  return f64_floor_to_int(x as Float64);
}

/// Float32 variant of f64_ceil_to_int. Complexity: O(1).
pub fn f32_ceil_to_int(x: Float32) -> Int {
  return f64_ceil_to_int(x as Float64);
}

/// Float32 variant of f64_trunc_to_int. Complexity: O(1).
pub fn f32_trunc_to_int(x: Float32) -> Int {
  return f64_trunc_to_int(x as Float64);
}

// ── Integer division helpers ────────────────────────────────────────────────
// Division by zero returns 0 (documented per function). INT_MIN / -1 wraps
// like two's-complement hardware (documented; use *_checked for safety).

/// Floor division: largest Int <= a/b (rounds toward -inf).
/// floor(-7, 2) == -4. Complexity: O(1).
pub fn i64_div_floor(a: Int, b: Int) -> Int {
  if b == 0 { return 0; }
  if a == INT_MIN && b == -1 { return INT_MIN; }
  var q = a / b;
  var r = a % b;
  if r != 0 && (r < 0) != (b < 0) { q = q - 1; }
  return q;
}

/// Ceiling division: smallest Int >= a/b (rounds toward +inf).
/// ceil(-7, 2) == -3. Complexity: O(1).
pub fn i64_div_ceil(a: Int, b: Int) -> Int {
  if b == 0 { return 0; }
  if a == INT_MIN && b == -1 { return INT_MIN; }
  var q = a / b;
  var r = a % b;
  if r != 0 && (r < 0) == (b < 0) { q = q + 1; }
  return q;
}

/// Division rounding to nearest, halves away from zero, using unsigned
/// magnitude arithmetic so the result is exact for the full i64 range
/// (saturating to INT_MAX/INT_MIN only for the unrepresentable +2^63).
/// Complexity: O(64) via u64_div_mod.
pub fn i64_div_round(a: Int, b: Int) -> Int {
  if b == 0 { return 0; }
  var neg = (a < 0) != (b < 0);
  var na = u64_mag(a);
  var nb = u64_mag(b);
  var dm = u64_div_mod(na, nb);
  var q = dm.quot;
  var r = dm.rem;
  var round_up = false;
  if u64_bit(r, 63) == 1 {
    round_up = true;
  } else {
    var twice = r + r;
    if u64_ge(twice, nb) { round_up = true; }
  }
  if round_up { q = q + 1; }
  if neg {
    if q == 0x8000000000000000 { return INT_MIN; }
    var z: UInt64 = 0;
    return (z - q) as Int;
  }
  if q == 0x8000000000000000 { return INT_MAX; }
  return q as Int;
}

/// Euclidean remainder: r >= 0 always, r ≡ a (mod b).
/// mod_euclid(-7, 2) == 1. Division by zero returns 0. Complexity: O(1).
pub fn i64_mod_euclid(a: Int, b: Int) -> Int {
  if b == 0 { return 0; }
  var r = a % b;
  if r < 0 {
    if b < 0 { return r - b; }
    return r + b;
  }
  return r;
}

/// Euclidean division: q = floor(a/b) (see i64_div_floor).
/// Complexity: O(1).
pub fn i64_div_euclid(a: Int, b: Int) -> Int {
  if b == 0 { return 0; }
  if a == INT_MIN && b == -1 { return INT_MIN; }
  var q = a / b;
  var r = a % b;
  if r < 0 { q = q - 1; }
  return q;
}

/// Unsigned floor division (identical to plain unsigned division).
/// Division by zero returns 0. Complexity: O(64).
pub fn u64_div_floor(a: UInt64, b: UInt64) -> UInt64 {
  if b == 0 {
    var z: UInt64 = 0;
    return z;
  }
  var dm = u64_div_mod(a, b);
  return dm.quot;
}

/// Unsigned ceiling division. Division by zero returns 0. Complexity: O(64).
pub fn u64_div_ceil(a: UInt64, b: UInt64) -> UInt64 {
  if b == 0 {
    var z: UInt64 = 0;
    return z;
  }
  var dm = u64_div_mod(a, b);
  if dm.rem != 0 {
    var one: UInt64 = 1;
    return dm.quot + one;
  }
  return dm.quot;
}

/// Unsigned Euclidean remainder (= plain unsigned remainder).
/// Division by zero returns 0. Complexity: O(64).
pub fn u64_mod_euclid(a: UInt64, b: UInt64) -> UInt64 {
  if b == 0 {
    var z: UInt64 = 0;
    return z;
  }
  var dm = u64_div_mod(a, b);
  return dm.rem;
}

/// Unsigned Euclidean division (identical to u64_div_floor).
/// Complexity: O(64).
pub fn u64_div_euclid(a: UInt64, b: UInt64) -> UInt64 {
  return u64_div_floor(a, b);
}

// ── Checked arithmetic: i64 ─────────────────────────────────────────────────
// Overflow-safe: return None on overflow/div-by-zero instead of wrapping.

/// a + b with overflow detection. Some(sum) on success, None on overflow.
/// Complexity: O(1).
pub fn i64_add_checked(a: Int, b: Int) -> Option[Int] {
  if b > 0 && a > INT_MAX - b { return None; }
  if b < 0 && a < INT_MIN - b { return None; }
  return Some(a + b);
}

/// a - b with overflow detection. Some(diff) on success, None on overflow.
/// Complexity: O(1).
pub fn i64_sub_checked(a: Int, b: Int) -> Option[Int] {
  if b < 0 && a > INT_MAX + b { return None; }
  if b > 0 && a < INT_MIN + b { return None; }
  return Some(a - b);
}

/// a * b with overflow detection. Some(product) on success, None on overflow.
/// Handles the ±1 edge cases explicitly. Complexity: O(1).
pub fn i64_mul_checked(a: Int, b: Int) -> Option[Int] {
  if a == 0 || b == 0 { return Some(0); }
  if a == -1 { return Some(-b); }
  if b == -1 { return Some(-a); }
  if a > 0 && b > 0 && a > INT_MAX / b { return None; }
  if a > 0 && b < 0 && b < INT_MIN / a { return None; }
  if a < 0 && b > 0 && a < INT_MIN / b { return None; }
  if a < 0 && b < 0 && a < INT_MAX / b { return None; }
  return Some(a * b);
}

/// a / b with div-by-zero and INT_MIN / -1 overflow detection.
/// Complexity: O(1).
pub fn i64_div_checked(a: Int, b: Int) -> Option[Int] {
  if b == 0 { return None; }
  if a == INT_MIN && b == -1 { return None; }
  return Some(a / b);
}

/// -a with overflow detection (INT_MIN has no positive inverse).
/// Complexity: O(1).
pub fn i64_neg_checked(a: Int) -> Option[Int] {
  if a == INT_MIN { return None; }
  return Some(-a);
}

/// base^exp with overflow detection via square-and-multiply.
/// Negative exponent returns None. Complexity: O(log exp).
pub fn i64_pow_checked(base: Int, exp: Int) -> Option[Int] {
  if exp < 0 { return None; }
  if exp == 0 { return Some(1); }
  var result = 1;
  var b = base;
  var e = exp;
  while e > 0 {
    if e % 2 == 1 {
      var m = i64_mul_checked(result, b);
      match m {
        Some(v) => { result = v; },
        None => { return None; },
      }
    }
    e = e / 2;
    if e > 0 {
      var m2 = i64_mul_checked(b, b);
      match m2 {
        Some(v) => { b = v; },
        None => { return None; },
      }
    }
  }
  return Some(result);
}

// ── Checked arithmetic: i32 / i16 / i8 ──────────────────────────────────────
// Small widths promote to i64 first: every intermediate is exact, so the
// only failure mode is the final range check.

/// i32 a + b. Some on success, None on overflow. Complexity: O(1).
pub fn i32_add_checked(a: Int32, b: Int32) -> Option[Int32] {
  var big: Int = (a as Int) + (b as Int);
  if big > 2147483647 || big < -2147483648 { return None; }
  return Some(big as Int32);
}

/// i32 a - b. Some on success, None on overflow. Complexity: O(1).
pub fn i32_sub_checked(a: Int32, b: Int32) -> Option[Int32] {
  var big: Int = (a as Int) - (b as Int);
  if big > 2147483647 || big < -2147483648 { return None; }
  return Some(big as Int32);
}

/// i32 a * b (i64 product is exact for all i32 inputs). None on overflow.
/// Complexity: O(1).
pub fn i32_mul_checked(a: Int32, b: Int32) -> Option[Int32] {
  var big: Int = (a as Int) * (b as Int);
  if big > 2147483647 || big < -2147483648 { return None; }
  return Some(big as Int32);
}

/// i32 a / b. None on div-by-zero or INT32_MIN / -1. Complexity: O(1).
pub fn i32_div_checked(a: Int32, b: Int32) -> Option[Int32] {
  if b == 0 { return None; }
  var big_a: Int = a as Int;
  var big_b: Int = b as Int;
  if big_a == -2147483648 && big_b == -1 { return None; }
  return Some((big_a / big_b) as Int32);
}

/// i16 a + b. None on overflow. Complexity: O(1).
pub fn i16_add_checked(a: Int16, b: Int16) -> Option[Int16] {
  var big: Int = (a as Int) + (b as Int);
  if big > 32767 || big < -32768 { return None; }
  return Some(big as Int16);
}

/// i16 a - b. None on overflow. Complexity: O(1).
pub fn i16_sub_checked(a: Int16, b: Int16) -> Option[Int16] {
  var big: Int = (a as Int) - (b as Int);
  if big > 32767 || big < -32768 { return None; }
  return Some(big as Int16);
}

/// i16 a * b. None on overflow. Complexity: O(1).
pub fn i16_mul_checked(a: Int16, b: Int16) -> Option[Int16] {
  var big: Int = (a as Int) * (b as Int);
  if big > 32767 || big < -32768 { return None; }
  return Some(big as Int16);
}

/// i16 a / b. None on div-by-zero or INT16_MIN / -1. Complexity: O(1).
pub fn i16_div_checked(a: Int16, b: Int16) -> Option[Int16] {
  if b == 0 { return None; }
  var big_a: Int = a as Int;
  var big_b: Int = b as Int;
  if big_a == -32768 && big_b == -1 { return None; }
  return Some((big_a / big_b) as Int16);
}

/// i8 a + b. None on overflow. Complexity: O(1).
pub fn i8_add_checked(a: Int8, b: Int8) -> Option[Int8] {
  var big: Int = (a as Int) + (b as Int);
  if big > 127 || big < -128 { return None; }
  return Some(big as Int8);
}

/// i8 a - b. None on overflow. Complexity: O(1).
pub fn i8_sub_checked(a: Int8, b: Int8) -> Option[Int8] {
  var big: Int = (a as Int) - (b as Int);
  if big > 127 || big < -128 { return None; }
  return Some(big as Int8);
}

/// i8 a * b. None on overflow. Complexity: O(1).
pub fn i8_mul_checked(a: Int8, b: Int8) -> Option[Int8] {
  var big: Int = (a as Int) * (b as Int);
  if big > 127 || big < -128 { return None; }
  return Some(big as Int8);
}

/// i8 a / b. None on div-by-zero or INT8_MIN / -1. Complexity: O(1).
pub fn i8_div_checked(a: Int8, b: Int8) -> Option[Int8] {
  if b == 0 { return None; }
  var big_a: Int = a as Int;
  var big_b: Int = b as Int;
  if big_a == -128 && big_b == -1 { return None; }
  return Some((big_a / big_b) as Int8);
}

// ── Checked arithmetic: unsigned widths ─────────────────────────────────────

/// u64 a + b using unsigned wrap detection. None on overflow.
/// Complexity: O(1).
pub fn u64_add_checked(a: UInt64, b: UInt64) -> Option[UInt64] {
  var sum = a + b;
  if !u64_ge(sum, a) { return None; }
  return Some(sum);
}

/// u64 a - b. None on underflow (a < b). Complexity: O(1).
pub fn u64_sub_checked(a: UInt64, b: UInt64) -> Option[UInt64] {
  if !u64_ge(a, b) { return None; }
  return Some(a - b);
}

/// u64 a * b via the exact 128-bit product; None when the high limb is non-zero.
/// Complexity: O(1).
pub fn u64_mul_checked(a: UInt64, b: UInt64) -> Option[UInt64] {
  if a == 0 || b == 0 { return Some(0); }
  var w = u64_mul_wide(a, b);
  if w.hi != 0 { return None; }
  return Some(w.lo);
}

/// u64 a / b. None on div-by-zero. Complexity: O(64).
pub fn u64_div_checked(a: UInt64, b: UInt64) -> Option[UInt64] {
  if b == 0 { return None; }
  var dm = u64_div_mod(a, b);
  return Some(dm.quot);
}

/// u32 a + b. None on overflow. Complexity: O(1).
pub fn u32_add_checked(a: UInt32, b: UInt32) -> Option[UInt32] {
  var big: Int = (a as Int) + (b as Int);
  if big > 4294967295 { return None; }
  return Some(big as UInt32);
}

/// u32 a - b. None on underflow. Complexity: O(1).
pub fn u32_sub_checked(a: UInt32, b: UInt32) -> Option[UInt32] {
  var big: Int = (a as Int) - (b as Int);
  if big < 0 { return None; }
  return Some(big as UInt32);
}

/// u32 a * b (i64 product is exact for all u32 inputs). None on overflow.
/// Complexity: O(1).
pub fn u32_mul_checked(a: UInt32, b: UInt32) -> Option[UInt32] {
  var big: Int = (a as Int) * (b as Int);
  if big > 4294967295 { return None; }
  return Some(big as UInt32);
}

/// u32 a / b. None on div-by-zero. Complexity: O(1).
pub fn u32_div_checked(a: UInt32, b: UInt32) -> Option[UInt32] {
  if b == 0 { return None; }
  return Some((a as Int / b as Int) as UInt32);
}

/// u16 a + b. None on overflow. Complexity: O(1).
pub fn u16_add_checked(a: UInt16, b: UInt16) -> Option[UInt16] {
  var big: Int = (a as Int) + (b as Int);
  if big > 65535 { return None; }
  return Some(big as UInt16);
}

/// u16 a - b. None on underflow. Complexity: O(1).
pub fn u16_sub_checked(a: UInt16, b: UInt16) -> Option[UInt16] {
  var big: Int = (a as Int) - (b as Int);
  if big < 0 { return None; }
  return Some(big as UInt16);
}

/// u16 a * b. None on overflow. Complexity: O(1).
pub fn u16_mul_checked(a: UInt16, b: UInt16) -> Option[UInt16] {
  var big: Int = (a as Int) * (b as Int);
  if big > 65535 { return None; }
  return Some(big as UInt16);
}

/// u16 a / b. None on div-by-zero. Complexity: O(1).
pub fn u16_div_checked(a: UInt16, b: UInt16) -> Option[UInt16] {
  if b == 0 { return None; }
  return Some((a as Int / b as Int) as UInt16);
}

/// u8 a + b. None on overflow. Complexity: O(1).
pub fn u8_add_checked(a: UInt8, b: UInt8) -> Option[UInt8] {
  var big: Int = (a as Int) + (b as Int);
  if big > 255 { return None; }
  return Some(big as UInt8);
}

/// u8 a - b. None on underflow. Complexity: O(1).
pub fn u8_sub_checked(a: UInt8, b: UInt8) -> Option[UInt8] {
  var big: Int = (a as Int) - (b as Int);
  if big < 0 { return None; }
  return Some(big as UInt8);
}

/// u8 a * b. None on overflow. Complexity: O(1).
pub fn u8_mul_checked(a: UInt8, b: UInt8) -> Option[UInt8] {
  var big: Int = (a as Int) * (b as Int);
  if big > 255 { return None; }
  return Some(big as UInt8);
}

/// u8 a / b. None on div-by-zero. Complexity: O(1).
pub fn u8_div_checked(a: UInt8, b: UInt8) -> Option[UInt8] {
  if b == 0 { return None; }
  return Some((a as Int / b as Int) as UInt8);
}

// ── Saturating arithmetic ───────────────────────────────────────────────────
// Clamp to the width's min/max instead of wrapping or failing.

/// Saturating i64 addition: clamps to INT_MAX/INT_MIN. Complexity: O(1).
pub fn i64_add_sat(a: Int, b: Int) -> Int {
  var o = i64_add_checked(a, b);
  match o {
    Some(v) => { return v; },
    None => {},
  }
  if b > 0 { return INT_MAX; }
  return INT_MIN;
}

/// Saturating i64 subtraction. Complexity: O(1).
pub fn i64_sub_sat(a: Int, b: Int) -> Int {
  var o = i64_sub_checked(a, b);
  match o {
    Some(v) => { return v; },
    None => {},
  }
  if b < 0 { return INT_MAX; }
  return INT_MIN;
}

/// Saturating i64 multiplication. Complexity: O(1).
pub fn i64_mul_sat(a: Int, b: Int) -> Int {
  var o = i64_mul_checked(a, b);
  match o {
    Some(v) => { return v; },
    None => {},
  }
  if (a > 0 && b > 0) || (a < 0 && b < 0) { return INT_MAX; }
  return INT_MIN;
}

/// Saturating u64 addition: clamps at 0xFFFFFFFFFFFFFFFF. Complexity: O(1).
pub fn u64_add_sat(a: UInt64, b: UInt64) -> UInt64 {
  var o = u64_add_checked(a, b);
  match o {
    Some(v) => { return v; },
    None => { return u64_max_value(); },
  }
}

/// Saturating u64 subtraction: clamps at 0 on underflow. Complexity: O(1).
pub fn u64_sub_sat(a: UInt64, b: UInt64) -> UInt64 {
  var o = u64_sub_checked(a, b);
  match o {
    Some(v) => { return v; },
    None => {
      var z: UInt64 = 0;
      return z;
    },
  }
}

/// Saturating u64 multiplication: clamps at 0xFFFFFFFFFFFFFFFF.
/// Complexity: O(1).
pub fn u64_mul_sat(a: UInt64, b: UInt64) -> UInt64 {
  var o = u64_mul_checked(a, b);
  match o {
    Some(v) => { return v; },
    None => { return u64_max_value(); },
  }
}

/// Saturating i32 addition. Complexity: O(1).
pub fn i32_add_sat(a: Int32, b: Int32) -> Int32 {
  var big: Int = (a as Int) + (b as Int);
  if big > 2147483647 { return 2147483647 as Int32; }
  if big < -2147483648 { return -2147483648 as Int32; }
  return big as Int32;
}

/// Saturating i32 subtraction. Complexity: O(1).
pub fn i32_sub_sat(a: Int32, b: Int32) -> Int32 {
  var big: Int = (a as Int) - (b as Int);
  if big > 2147483647 { return 2147483647 as Int32; }
  if big < -2147483648 { return -2147483648 as Int32; }
  return big as Int32;
}

/// Saturating i32 multiplication. Complexity: O(1).
pub fn i32_mul_sat(a: Int32, b: Int32) -> Int32 {
  var big: Int = (a as Int) * (b as Int);
  if big > 2147483647 { return 2147483647 as Int32; }
  if big < -2147483648 { return -2147483648 as Int32; }
  return big as Int32;
}

/// Saturating u32 addition: clamps at 4294967295. Complexity: O(1).
pub fn u32_add_sat(a: UInt32, b: UInt32) -> UInt32 {
  var big: Int = (a as Int) + (b as Int);
  if big > 4294967295 { return 4294967295 as UInt32; }
  return big as UInt32;
}

/// Saturating u32 subtraction: clamps at 0. Complexity: O(1).
pub fn u32_sub_sat(a: UInt32, b: UInt32) -> UInt32 {
  var big: Int = (a as Int) - (b as Int);
  if big < 0 { return 0 as UInt32; }
  return big as UInt32;
}

/// Saturating u32 multiplication. Complexity: O(1).
pub fn u32_mul_sat(a: UInt32, b: UInt32) -> UInt32 {
  var big: Int = (a as Int) * (b as Int);
  if big > 4294967295 { return 4294967295 as UInt32; }
  return big as UInt32;
}

// ── Int128: construction ────────────────────────────────────────────────────
// D1: Int128 is a native i128 primitive. All ops below are direct hardware
// instructions (add/sub/mul) or runtime libcalls (div/rem via __divti3).

/// Constructs an Int128 from a signed 64-bit value (sign-extended).
/// Complexity: O(1).
pub fn i128_from_i64(v: Int) -> Int128 {
  return v as Int128;
}

/// Constructs an Int128 directly from a high signed limb and a low unsigned
/// limb (value = hi * 2^64 + lo). Complexity: O(1).
pub fn i128_from_parts(hi: Int, lo: UInt64) -> Int128 {
  var h = hi as Int128;
  var l = lo as UInt128 as Int128;
  return (h << 64) | l;
}

// ── Int128: arithmetic (wrapping at 128 bits) ───────────────────────────────

/// 128-bit addition (wraps on overflow). Complexity: O(1).
pub fn i128_add(a: Int128, b: Int128) -> Int128 {
  return a + b;
}

/// 128-bit subtraction (wraps on underflow). Complexity: O(1).
pub fn i128_sub(a: Int128, b: Int128) -> Int128 {
  return a - b;
}

/// Two's-complement negation. Handles INT128_MIN correctly (wraps back to
/// itself, as required by two's-complement arithmetic). Complexity: O(1).
pub fn i128_neg(a: Int128) -> Int128 {
  return 0 as Int128 - a;
}

/// Absolute value (returns the negated value for INT128_MIN, documenting the
/// two's-complement wrap). Complexity: O(1).
pub fn i128_abs(a: Int128) -> Int128 {
  if a < (0 as Int128) { return i128_neg(a); }
  return a;
}

/// Full 128-bit product of two 64-bit signed values.
/// i64_mul_wide(2^32, 2^32) == { hi: 1, lo: 0 } == 2^64. Exact.
/// Complexity: O(1).
pub fn i64_mul_wide(a: Int, b: Int) -> Int128 {
  var aw = a as Int128;
  var bw = b as Int128;
  return aw * bw;
}

/// 128 x 128 multiplication (result is modulo 2^128; low 128 bits are exact
/// regardless of signedness). Complexity: O(1) — native i128 mul.
pub fn i128_mul(a: Int128, b: Int128) -> Int128 {
  return a * b;
}

// ── Int128: comparison & predicates ─────────────────────────────────────────

/// Three-way comparison (-1/0/1). Complexity: O(1).
pub fn i128_compare(a: Int128, b: Int128) -> Int {
  if a < b { return -1; }
  if a > b { return 1; }
  return 0;
}

/// Returns true iff the value is exactly zero. Complexity: O(1).
pub fn i128_is_zero(a: Int128) -> Bool {
  return a == (0 as Int128);
}

/// Returns true iff the value is negative (top bit set). Complexity: O(1).
pub fn i128_is_negative(a: Int128) -> Bool {
  return a < (0 as Int128);
}

// ── Int128: conversion ──────────────────────────────────────────────────────

/// Converts to i64; None if the value does not fit in a signed 64-bit range.
/// Complexity: O(1).
pub fn i128_to_i64(a: Int128) -> Option[Int] {
  if a >= (-9223372036854775808 as Int128) && a <= (9223372036854775807 as Int128) {
    return Some(a as Int);
  }
  return None;
}

/// Decimal string representation, handling the sign.
/// Exact for the full Int128 range, including INT128_MIN.
/// Complexity: O(128 * digits) ~ O(1) bounded by 39 digits.
///
/// NOTE (2026-08-08): uses 64-bit limb arithmetic, NOT native i128 div/rem —
/// the sdiv/srem i128 libcalls (__divti3/__modti3) inside a multi-iteration
/// loop with memory ops miscompile at clang -O2 (verified repeatedly). The
/// limb algorithm is exact (e2e-proven pre-D1) and works at every opt level.
pub fn i128_to_str(a: Int128) -> Str {
  if i128_is_zero(a) { return "0"; }
  var neg = a < (0 as Int128);
  var n = a;
  if neg { n = i128_neg(a); }
  // Extract 64-bit limbs: hi = bits 64..127 (unsigned), lo = bits 0..63.
  var hi: UInt64 = ((n >> 64) & (0xFFFFFFFFFFFFFFFF as UInt128 as Int128)) as UInt64;
  var lo: UInt64 = (n & (0xFFFFFFFFFFFFFFFF as UInt128 as Int128)) as UInt64;
  var digits = Vec[Int].new();
  var d: UInt64 = 10;
  // 2^64 / 10 = 1844674407370955161 remainder 6 (exact).
  var k: UInt64 = 1844674407370955161;
  var guard = 0;
  while guard < 40 {
    if hi == 0 && lo == 0 { break; }
    // Full value = hi*2^64 + lo. Divide by 10 using u64 limb arithmetic:
    //   hi_qr = hi / 10, rem_hi = hi % 10 (carry < 10)
    //   (hi*2^64 + lo) = 10*(hi_qr.quot*2^64) + (rem_hi*2^64 + lo)
    //   (rem_hi*2^64 + lo) = rem_hi*(10k+6) + lo = 10*(rem_hi*k) + (rem_hi*6 + lo)
    var hi_qr = u64_div_mod(hi, d);
    var carry = hi_qr.rem;
    var lo_qr = u64_div_mod(lo, d);
    var mixed = carry * 6 + lo_qr.rem;
    var rem = mixed % 10;
    var q_hi = hi_qr.quot;
    var q_lo = carry * k + lo_qr.quot + mixed / d;
    digits.push(rem as Int);
    hi = q_hi;
    lo = q_lo;
    guard = guard + 1;
  }
  var result = "";
  if neg { result = "-"; }
  var i = digits.len() - 1;
  while i >= 0 {
    result = str_concat(result, _digit_char(digits[i]));
    i = i - 1;
  }
  return result;
}

/// Parses a decimal string (optional +/- prefix) into an Int128.
/// Returns Err on invalid characters, empty input, or overflow beyond the
/// 128-bit range.
/// Complexity: O(digits * 128) ~ O(1).
pub fn i128_from_str(s: Str) -> Result[Int128, Str] {
  if s.len() == 0 { return Err("empty string"); }
  var neg = false;
  var start = 0;
  var c0 = char_at(s, 0);
  if c0.is_some {
    var ch = c0.value;
    if ch == '-' {
      neg = true;
      start = 1;
    } elif ch == '+' {
      start = 1;
    }
  }
  if start >= s.len() { return Err("no digits"); }
  var result = i128_zero();
  var i = start;
  while i < s.len() {
    var opt = char_at(s, i);
    if !opt.is_some { return Err("bad index"); }
    var c = opt.value;
    if c < '0' || c > '9' { return Err("invalid digit"); }
    var digit = to_int_from_char(c) - to_int_from_char('0');
    result = _i128_mul_small(result, 10);
    if i128_is_negative(result) { return Err("overflow"); }
    result = _i128_add_small(result, digit);
    if i128_is_negative(result) { return Err("overflow"); }
    i = i + 1;
  }
  if neg {
    if i128_is_zero(result) { return Ok(result); }
    return Ok(i128_neg(result));
  }
  return Ok(result);
}

// ── Int128: shifts ──────────────────────────────────────────────────────────

/// Arithmetic shift left by n bits (wraps at 128 bits). n >= 128 yields zero.
/// Complexity: O(1).
pub fn i128_shl(a: Int128, n: Int) -> Int128 {
  if n <= 0 { return a; }
  if n >= 128 { return i128_zero(); }
  return a << n;
}

/// Arithmetic shift right by n bits (sign-extending). For n >= 128 the result
/// is the sign (all ones for negatives, zero otherwise). Complexity: O(1).
pub fn i128_shr(a: Int128, n: Int) -> Int128 {
  if n <= 0 { return a; }
  if n >= 128 {
    if i128_is_negative(a) { return 0 as Int128 - 1 as Int128; }
    return i128_zero();
  }
  return a >> n;
}

/// a*b/c evaluated with a 128-bit intermediate, then clamped (saturated) to
/// the i64 range. c == 0 returns 0 (documented). Exact for all i64 inputs.
/// Complexity: O(1) — native i128 mul + div.
pub fn i64_mul_div(a: Int, b: Int, c: Int) -> Int {
  if c == 0 { return 0; }
  var w = i64_mul_wide(a, b);
  var q = w / (c as Int128);
  var top = q >> 64;
  var sign_ok = !i128_is_negative(q) || (top == (0 as Int128 - 1 as Int128));
  if !sign_ok { return INT_MIN; }
  if i128_is_negative(q) {
    if q < (-9223372036854775808 as Int128) { return INT_MIN; }
    return q as Int;
  }
  if q > (9223372036854775807 as Int128) { return INT_MAX; }
  return q as Int;
}

// ── Int128: internal helpers ────────────────────────────────────────────────

/// Divides a NON-NEGATIVE Int128 by a positive scalar d and returns the
/// quotient and remainder (remainder in [0, d)). D1: native div/rem.
/// Complexity: O(1).
fn _i128_div_rem_small(a: Int128, d: Int) -> I128DivRem {
  var dl = d as Int128;
  var q = a / dl;
  var r = a % dl;
  return I128DivRem{ quot: q; rem: r as Int; };
}

/// Multiplies an Int128 by a small positive scalar m (e.g. 10). D1: native.
/// Complexity: O(1).
fn _i128_mul_small(a: Int128, m: Int) -> Int128 {
  return a * (m as Int128);
}

/// Adds a small non-negative scalar v to an Int128. D1: native.
/// Complexity: O(1).
fn _i128_add_small(a: Int128, v: Int) -> Int128 {
  return a + (v as Int128);
}

/// Maps a digit 0-9 to its single-character string. Complexity: O(1).
fn _digit_char(d: Int) -> Str {
  if d == 0 { return "0"; }
  if d == 1 { return "1"; }
  if d == 2 { return "2"; }
  if d == 3 { return "3"; }
  if d == 4 { return "4"; }
  if d == 5 { return "5"; }
  if d == 6 { return "6"; }
  if d == 7 { return "7"; }
  if d == 8 { return "8"; }
  return "9";
}

// ── Cross-type conversions: integers (bounds-checked) ───────────────────────
// Each conversion validates the source value against the target range and
// returns None on failure, so all-widths math is safe by construction.

/// u8 from i64: Some(v) iff 0 <= v <= 255. Complexity: O(1).
pub fn u8_from_i64(v: Int) -> Option[Int] {
  if v < 0 || v > 255 { return None; }
  return Some(v);
}

/// u8 from i32 (promoted through i64 arithmetic). Complexity: O(1).
pub fn u8_from_i32(v: Int32) -> Option[Int] {
  var big: Int = v as Int;
  if big < 0 || big > 255 { return None; }
  return Some(big);
}

/// u16 from i64: Some(v) iff 0 <= v <= 65535. Complexity: O(1).
pub fn u16_from_i64(v: Int) -> Option[Int] {
  if v < 0 || v > 65535 { return None; }
  return Some(v);
}

/// u32 from i64: Some(v) iff 0 <= v <= 4294967295. Complexity: O(1).
pub fn u32_from_i64(v: Int) -> Option[Int] {
  if v < 0 || v > 4294967295 { return None; }
  return Some(v);
}

/// u64 from i64: Some(v) iff v >= 0. Complexity: O(1).
pub fn u64_from_i64(v: Int) -> Option[UInt64] {
  if v < 0 { return None; }
  return Some(v as UInt64);
}

/// i8 from i64: Some(v) iff -128 <= v <= 127. Complexity: O(1).
pub fn i8_from_i64(v: Int) -> Option[Int] {
  if v < -128 || v > 127 { return None; }
  return Some(v);
}

/// i16 from i64: Some(v) iff -32768 <= v <= 32767. Complexity: O(1).
pub fn i16_from_i64(v: Int) -> Option[Int] {
  if v < -32768 || v > 32767 { return None; }
  return Some(v);
}

/// i32 from i64: Some(v) iff -2147483648 <= v <= 2147483647. Complexity: O(1).
pub fn i32_from_i64(v: Int) -> Option[Int] {
  if v < -2147483648 || v > 2147483647 { return None; }
  return Some(v);
}

/// i64 from u64: Some(v) iff v has the top bit clear. Complexity: O(1).
pub fn i64_from_u64(v: UInt64) -> Option[Int] {
  if u64_bit(v, 63) == 1 { return None; }
  return Some(v as Int);
}

/// i64 from i32: always fits. Complexity: O(1).
pub fn i64_from_i32(v: Int32) -> Int {
  return v as Int;
}

/// i64 from i16: always fits. Complexity: O(1).
pub fn i64_from_i16(v: Int16) -> Int {
  return v as Int;
}

/// i64 from i8: always fits. Complexity: O(1).
pub fn i64_from_i8(v: Int8) -> Int {
  return v as Int;
}

/// i64 from u8: always fits. Complexity: O(1).
pub fn i64_from_u8(v: UInt8) -> Int {
  return v as Int;
}

/// i64 from u16: always fits. Complexity: O(1).
pub fn i64_from_u16(v: UInt16) -> Int {
  return v as Int;
}

/// i64 from u32: always fits. Complexity: O(1).
pub fn i64_from_u32(v: UInt32) -> Int {
  return v as Int;
}

// ── Cross-type conversions: float construction ──────────────────────────────

/// Float64 from i64 (lossless only for |v| < 2^53; rounds beyond).
/// Complexity: O(1).
pub fn f64_from_int(v: Int) -> Float64 {
  return v as Float64;
}

/// Float64 from i32: always exact. Complexity: O(1).
pub fn f64_from_i32(v: Int32) -> Float64 {
  return (v as Int) as Float64;
}

/// Float64 from u64: exact split into two 32-bit halves avoids relying on
/// unsigned-to-float conversions for values above i64::MAX. Complexity: O(1).
pub fn f64_from_u64(v: UInt64) -> Float64 {
  var hi = u64_logical_shr(v, 32);
  var lo = v & 0xFFFFFFFF;
  var fhi = (hi as Int) as Float64;
  var flo = (lo as Int) as Float64;
  return fhi * 4294967296.0 + flo;
}

/// Float32 from i64 (rounds for |v| > 2^24). Complexity: O(1).
pub fn f32_from_int(v: Int) -> Float32 {
  return (v as Float64) as Float32;
}

/// Float32 from Float64 (round-to-nearest; inf/NaN propagate). Complexity: O(1).
pub fn f32_from_f64(v: Float64) -> Float32 {
  return v as Float32;
}

/// Float64 from Float32: always exact. Complexity: O(1).
pub fn f64_from_f32(v: Float32) -> Float64 {
  return v as Float64;
}

// ── Cross-type conversions: float -> integer (bounds-checked) ───────────────

/// Truncating conversion Float64 -> Int. None on NaN or out-of-i64-range.
/// Complexity: O(1).
pub fn int_from_f64_trunc(v: Float64) -> Option[Int] {
  if is_nan(v) { return None; }
  if v >= 9223372036854775808.0 { return None; }
  if v < -9223372036854775808.0 { return None; }
  return Some(to_int(v));
}

/// Rounding conversion Float64 -> Int (round-half-away-from-zero).
/// None on NaN or out-of-range. Complexity: O(1).
pub fn int_from_f64_round(v: Float64) -> Option[Int] {
  if is_nan(v) { return None; }
  if v >= 9223372036854775808.0 { return None; }
  if v < -9223372036854775808.0 { return None; }
  if v >= 0.0 { return int_from_f64_trunc(v + 0.5); }
  return int_from_f64_trunc(v - 0.5);
}

/// Truncating conversion Float64 -> Int32. None on NaN, out-of-i64-range,
/// or outside the Int32 range. Complexity: O(1).
pub fn i32_from_f64_trunc(v: Float64) -> Option[Int32] {
  var o = int_from_f64_trunc(v);
  match o {
    Some(x) => {
      if x >= -2147483648 && x <= 2147483647 { return Some(x as Int32); }
      return None;
    },
    None => { return None; },
  }
}

/// Rounding conversion Float64 -> Int32 (round-half-away-from-zero).
/// Complexity: O(1).
pub fn i32_from_f64_round(v: Float64) -> Option[Int32] {
  var o = int_from_f64_round(v);
  match o {
    Some(x) => {
      if x >= -2147483648 && x <= 2147483647 { return Some(x as Int32); }
      return None;
    },
    None => { return None; },
  }
}

/// Truncating conversion Float64 -> UInt64. None on NaN, negatives, or
/// values >= 2^64. Handles the high half without unsigned-to-int casts.
/// Complexity: O(1).
pub fn u64_from_f64_trunc(v: Float64) -> Option[UInt64] {
  if is_nan(v) { return None; }
  if v < 0.0 { return None; }
  if v >= 18446744073709551616.0 { return None; }
  if v < 9223372036854775808.0 { return Some(to_int(v) as UInt64); }
  var hi_part = to_int(v - 9223372036854775808.0);
  var res: UInt64 = hi_part as UInt64;
  var base: UInt64 = 0x8000000000000000;
  return Some(res + base);
}

/// Truncating conversion Float32 -> Int. Complexity: O(1).
pub fn int_from_f32_trunc(v: Float32) -> Option[Int] {
  return int_from_f64_trunc(v as Float64);
}

/// Rounding conversion Float32 -> Int (round-half-away-from-zero).
/// Complexity: O(1).
pub fn int_from_f32_round(v: Float32) -> Option[Int] {
  return int_from_f64_round(v as Float64);
}

/// Bounds-checked integer parse in the given radix (2..36).
/// Reuses parse_int_radix; None on invalid input or overflow.
/// Complexity: O(len(s)).
pub fn int_from_str_radix_checked(s: Str, radix: Int) -> Option[Int] {
  if s.len() == 0 { return None; }
  if radix < 2 || radix > 36 { return None; }
  var res = parse_int_radix(s, radix);
  match res {
    Ok(v) => { return Some(v); },
    Err(_) => { return None; },
  }
}

// ── Per-width absolute value ────────────────────────────────────────────────

/// Absolute value of an i64. NOTE: |INT_MIN| wraps to INT_MIN
/// (two's-complement); use i64_neg_checked for overflow-safe negation.
/// Complexity: O(1).
pub fn i64_abs(v: Int) -> Int {
  if v < 0 { return -v; }
  return v;
}

/// Absolute value of an i32. |INT32_MIN| wraps to INT32_MIN. Complexity: O(1).
pub fn i32_abs(v: Int32) -> Int32 {
  var big: Int = v as Int;
  if big < 0 { big = -big; }
  return big as Int32;
}

/// Absolute value of an i16. |INT16_MIN| wraps to INT16_MIN. Complexity: O(1).
pub fn i16_abs(v: Int16) -> Int16 {
  var big: Int = v as Int;
  if big < 0 { big = -big; }
  return big as Int16;
}

/// Absolute value of an i8. |INT8_MIN| wraps to INT8_MIN. Complexity: O(1).
pub fn i8_abs(v: Int8) -> Int8 {
  var big: Int = v as Int;
  if big < 0 { big = -big; }
  return big as Int8;
}

/// Absolute value of a Float64 (fabs; -0.0 becomes +0.0, NaN propagates).
/// Complexity: O(1).
pub fn f64_abs(x: Float64) -> Float64 {
  if x >= 0.0 { return x; }
  return -x;
}

/// Absolute value of a Float32. Complexity: O(1).
pub fn f32_abs(x: Float32) -> Float32 {
  if x >= 0.0 { return x; }
  return -x;
}

// ── Per-width clamp ─────────────────────────────────────────────────────────

/// Clamps v to the inclusive range [lo, hi]. Complexity: O(1).
pub fn i64_clamp(v: Int, lo: Int, hi: Int) -> Int {
  if v < lo { return lo; }
  if v > hi { return hi; }
  return v;
}

/// Clamps an i32 (promoted to i64 arithmetic). Complexity: O(1).
pub fn i32_clamp(v: Int32, lo: Int32, hi: Int32) -> Int32 {
  var big_v: Int = v as Int;
  var big_lo: Int = lo as Int;
  var big_hi: Int = hi as Int;
  if big_v < big_lo { return lo; }
  if big_v > big_hi { return hi; }
  return v;
}

/// Clamps a u64 using unsigned comparisons (avoids the signed `>` bug).
/// Complexity: O(1).
pub fn u64_clamp(v: UInt64, lo: UInt64, hi: UInt64) -> UInt64 {
  if !u64_ge(v, lo) { return lo; }
  if !u64_ge(hi, v) { return hi; }
  return v;
}

/// Clamps a Float64. Complexity: O(1).
pub fn f64_clamp(x: Float64, lo: Float64, hi: Float64) -> Float64 {
  if x < lo { return lo; }
  if x > hi { return hi; }
  return x;
}

/// Clamps a Float32. Complexity: O(1).
pub fn f32_clamp(x: Float32, lo: Float32, hi: Float32) -> Float32 {
  if x < lo { return lo; }
  if x > hi { return hi; }
  return x;
}

// ── Per-width signum ────────────────────────────────────────────────────────

/// -1/0/1 for negative/zero/positive i64. Complexity: O(1).
pub fn i64_signum(v: Int) -> Int {
  if v > 0 { return 1; }
  if v < 0 { return -1; }
  return 0;
}

/// -1/0/1 for i32. Complexity: O(1).
pub fn i32_signum(v: Int32) -> Int {
  if v > 0 { return 1; }
  if v < 0 { return -1; }
  return 0;
}

/// -1.0/0.0/1.0 for a Float64. NaN returns NaN (IEEE signum semantics).
/// Complexity: O(1).
pub fn f64_signum(v: Float64) -> Float64 {
  if v != v { return v; }
  if v > 0.0 { return 1.0; }
  if v < 0.0 { return -1.0; }
  return 0.0;
}

/// -1.0/0.0/1.0 for a Float32. NaN returns NaN. Complexity: O(1).
pub fn f32_signum(v: Float32) -> Float32 {
  if v != v { return v; }
  if v > 0.0 { return 1.0; }
  if v < 0.0 { return -1.0; }
  return 0.0;
}

// ── Per-width power ─────────────────────────────────────────────────────────

/// base^exp for i64 via square-and-multiply. Overflows WRAP (documented);
/// use i64_pow_checked for overflow detection. Negative exponent returns 0.
/// Complexity: O(log exp).
pub fn i64_pow(base: Int, exp: Int) -> Int {
  if exp < 0 { return 0; }
  if exp == 0 { return 1; }
  var result = 1;
  var b = base;
  var e = exp;
  while e > 0 {
    if e % 2 == 1 { result = result * b; }
    e = e / 2;
    if e > 0 { b = b * b; }
  }
  return result;
}

/// base^exp for u64. Overflows WRAP (documented). Negative exponent returns 0.
/// Complexity: O(log exp).
pub fn u64_pow(base: UInt64, exp: Int) -> UInt64 {
  if exp < 0 {
    var z: UInt64 = 0;
    return z;
  }
  if exp == 0 {
    var one: UInt64 = 1;
    return one;
  }
  var result: UInt64 = 1;
  var b = base;
  var e = exp;
  while e > 0 {
    if e % 2 == 1 { result = result * b; }
    e = e / 2;
    if e > 0 { b = b * b; }
  }
  return result;
}

/// base^exp for i32 (wraps at 32 bits; documented). Negative exponent returns 0.
/// Complexity: O(log exp).
pub fn i32_pow(base: Int32, exp: Int) -> Int32 {
  if exp < 0 { return 0 as Int32; }
  if exp == 0 { return 1 as Int32; }
  var result: Int32 = 1;
  var b = base;
  var e = exp;
  while e > 0 {
    if e % 2 == 1 { result = result * b; }
    e = e / 2;
    if e > 0 { b = b * b; }
  }
  return result;
}

/// Float64 power, delegating to xiom.math.pow. Negative bases require an
/// integer exponent; otherwise returns NaN. Exponent outside the i64 range
/// returns NaN (documented edge). Complexity: O(log exp) via libm.
pub fn f64_pow(base: Float64, exp: Float64) -> Float64 {
  if base < 0.0 {
    if exp >= 9223372036854775808.0 || exp < -9223372036854775808.0 {
      return 0.0 / 0.0;
    }
    var exp_i = to_int(exp);
    if (exp_i as Float64) != exp { return 0.0 / 0.0; }
    var positive = pow(-base, exp);
    if exp_i % 2 == 0 { return positive; }
    return -positive;
  }
  return pow(base, exp);
}

/// Float32 power (promoted through f64_pow). Complexity: O(log exp).
pub fn f32_pow(base: Float32, exp: Float32) -> Float32 {
  return f64_pow(base as Float64, exp as Float64) as Float32;
}

// ── Per-width extrema ───────────────────────────────────────────────────────

/// Minimum of three i64 values. Concrete (generic min3 needs Ord dispatch).
/// Complexity: O(1).
pub fn i64_min_of3(a: Int, b: Int, c: Int) -> Int {
  if a < b {
    if a < c { return a; }
    return c;
  }
  if b < c { return b; }
  return c;
}

/// Maximum of three i64 values. Complexity: O(1).
pub fn i64_max_of3(a: Int, b: Int, c: Int) -> Int {
  if a > b {
    if a > c { return a; }
    return c;
  }
  if b > c { return b; }
  return c;
}

// ── Fraction (rational) arithmetic ──────────────────────────────────────────
// Invariants: den > 0, gcd(|num|, den) == 1. Cross-multiplication can
// overflow i64 for large numerators/denominators (documented on the
// operations that use it); pre-reduction via gcd is applied where possible.

/// Builds a reduced fraction from num/den, normalizing the sign to the
/// denominator. den == 0 returns the zero fraction (documented).
/// Complexity: O(log max(|num|, |den|)) for gcd.
pub fn fraction_new(num: Int, den: Int) -> Fraction {
  if den == 0 { return Fraction{ num: 0; den: 1; }; }
  var g = gcd(num, den);
  if g < 0 { g = -g; }
  if g == 0 { g = 1; }
  var n = num / g;
  var d = den / g;
  if d < 0 {
    n = -n;
    d = -d;
  }
  return Fraction{ num: n; den: d; };
}

/// Builds the fraction v/1. Complexity: O(1).
pub fn fraction_from_int(v: Int) -> Fraction {
  return Fraction{ num: v; den: 1; };
}

/// The zero fraction 0/1. Complexity: O(1).
pub fn fraction_zero() -> Fraction {
  return Fraction{ num: 0; den: 1; };
}

/// The one fraction 1/1. Complexity: O(1).
pub fn fraction_one() -> Fraction {
  return Fraction{ num: 1; den: 1; };
}

/// a + b. Pre-reduces by gcd(a.den, b.den) to limit overflow; the final
/// result is re-reduced. Cross-products may still overflow i64 for very
/// large denominators (documented). Complexity: O(log max(den)).
pub fn fraction_add(a: &Fraction, b: &Fraction) -> Fraction {
  var g = gcd(a.den, b.den);
  if g < 0 { g = -g; }
  var num = (a.num / g) * b.den + (b.num / g) * a.den;
  var den = (a.den / g) * b.den;
  return fraction_new(num, den);
}

/// a - b. Complexity: O(log max(den)).
pub fn fraction_sub(a: &Fraction, b: &Fraction) -> Fraction {
  var neg_b = Fraction{ num: -b.num; den: b.den; };
  return fraction_add(a, &neg_b);
}

/// a * b. Cross-cancels via gcd before multiplying, minimizing overflow.
/// Complexity: O(log max(|num|, den)).
pub fn fraction_mul(a: &Fraction, b: &Fraction) -> Fraction {
  var g1 = gcd(a.num, b.den);
  if g1 < 0 { g1 = -g1; }
  var g2 = gcd(b.num, a.den);
  if g2 < 0 { g2 = -g2; }
  var num = (a.num / g1) * (b.num / g2);
  var den = (a.den / g2) * (b.den / g1);
  return fraction_new(num, den);
}

/// a / b (flip b and multiply). Dividing by the zero fraction yields zero
/// (documented). Complexity: O(log max(|num|, den)).
pub fn fraction_div(a: &Fraction, b: &Fraction) -> Fraction {
  var r = fraction_reciprocal(b);
  return fraction_mul(a, &r);
}

/// -a. Complexity: O(1).
pub fn fraction_neg(a: &Fraction) -> Fraction {
  return Fraction{ num: -a.num; den: a.den; };
}

/// Three-way comparison via cross-multiplication. Cross-products can
/// overflow i64 for large fractions (documented). Complexity: O(1).
pub fn fraction_compare(a: Fraction, b: Fraction) -> Int {
  var lhs = a.num * b.den;
  var rhs = b.num * a.den;
  if lhs < rhs { return -1; }
  if lhs > rhs { return 1; }
  return 0;
}

/// Returns true iff the fraction is zero. Complexity: O(1).
pub fn fraction_is_zero(a: Fraction) -> Bool {
  return a.num == 0;
}

/// The numerator. Complexity: O(1).
pub fn fraction_num(a: Fraction) -> Int {
  return a.num;
}

/// The denominator (always > 0). Complexity: O(1).
pub fn fraction_den(a: Fraction) -> Int {
  return a.den;
}

/// Converts to Float64 (numerator/denominator division). Complexity: O(1).
pub fn fraction_to_float(a: Fraction) -> Float64 {
  return (a.num as Float64) / (a.den as Float64);
}

/// Converts to Float32. Complexity: O(1).
pub fn fraction_to_float32(a: Fraction) -> Float32 {
  return ((a.num as Float64) / (a.den as Float64)) as Float32;
}

/// Renders as "num/den". Complexity: O(1) string building.
pub fn fraction_to_str(a: Fraction) -> Str {
  return str_concat(to_string(a.num), str_concat("/", to_string(a.den)));
}

/// Parses "num/den" (optional signs on each part). None on malformed input,
/// empty parts, or a zero denominator. Complexity: O(len(s)).
pub fn fraction_from_str(s: Str) -> Option[Fraction] {
  if s.len() == 0 { return None; }
  var slash = -1;
  var i = 0;
  while i < s.len() {
    var opt = char_at(s, i);
    if opt.is_some {
      var c = opt.value;
      if c == '/' { slash = i; }
    }
    i = i + 1;
  }
  if slash <= 0 || slash >= s.len() - 1 { return None; }
  var num_str = str_slice(s, 0, slash);
  var den_str = str_slice(s, slash + 1, s.len());
  var num = 0;
  var den = 0;
  var num_res = to_int_from_str(num_str);
  match num_res {
    Ok(v) => { num = v; },
    Err(_) => { return None; },
  }
  var den_res = to_int_from_str(den_str);
  match den_res {
    Ok(v) => { den = v; },
    Err(_) => { return None; },
  }
  if den == 0 { return None; }
  return Some(fraction_new(num, den));
}

/// 1/a (den/num). The zero fraction has no reciprocal; returns zero.
/// Complexity: O(log max(|num|, den)).
pub fn fraction_reciprocal(a: &Fraction) -> Fraction {
  if a.num == 0 { return fraction_zero(); }
  return fraction_new(a.den, a.num);
}

/// a^n for integer exponents. Negative n raises the reciprocal; n == 0
/// returns one. n == INT_MIN returns zero (documented overflow edge).
/// Complexity: O(log |n|).
pub fn fraction_pow_int(a: Fraction, n: Int) -> Fraction {
  if n == 0 { return fraction_one(); }
  if n == INT_MIN { return fraction_zero(); }
  var base = a;
  var e = n;
  if e < 0 {
    base = fraction_reciprocal(&a);
    e = -e;
  }
  var result = fraction_one();
  while e > 0 {
    if e % 2 == 1 { result = fraction_mul(&result, &base); }
    e = e / 2;
    if e > 0 { base = fraction_mul(&base, &base); }
  }
  return result;
}

/// Returns true iff |num| < den (a proper fraction). NOTE: |INT_MIN| wraps
/// (documented); proper tests near the i64 extreme are degenerate.
/// Complexity: O(1).
pub fn fraction_is_proper(a: Fraction) -> Bool {
  var n = a.num;
  if n < 0 { n = -n; }
  return n < a.den;
}

// ── Per-width lerp ──────────────────────────────────────────────────────────

/// Integer lerp: a + (b - a) * t with t clamped to [0, 1]. For i64, t is
/// effectively 0 or 1. NOTE: (b - a) * t can overflow i64 for extreme ranges
/// (documented). Complexity: O(1).
pub fn i64_lerp(a: Int, b: Int, t: Int) -> Int {
  var tt = t;
  if tt < 0 { tt = 0; }
  if tt > 1 { tt = 1; }
  return a + (b - a) * tt;
}

/// Float64 lerp: a + (b - a) * t. Complexity: O(1).
pub fn f64_lerp(a: Float64, b: Float64, t: Float64) -> Float64 {
  return a + (b - a) * t;
}

/// Float32 lerp: a + (b - a) * t. Complexity: O(1).
pub fn f32_lerp(a: Float32, b: Float32, t: Float32) -> Float32 {
  return a + (b - a) * t;
}

/// Inverse lerp: (v - a) / (b - a), clamped to [0, 1]. If b == a, returns 0
/// (documented). Complexity: O(1).
pub fn f64_inverse_lerp(a: Float64, b: Float64, v: Float64) -> Float64 {
  if b == a { return 0.0; }
  var t = (v - a) / (b - a);
  if t < 0.0 { return 0.0; }
  if t > 1.0 { return 1.0; }
  return t;
}

/// Remaps v from the range [in_lo, in_hi] to [out_lo, out_hi] (linear).
/// If in_hi == in_lo, returns out_lo (documented). Complexity: O(1).
pub fn f64_remap(v: Float64, in_lo: Float64, in_hi: Float64, out_lo: Float64, out_hi: Float64) -> Float64 {
  if in_hi == in_lo { return out_lo; }
  var t = (v - in_lo) / (in_hi - in_lo);
  return out_lo + t * (out_hi - out_lo);
}
