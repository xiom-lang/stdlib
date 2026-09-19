// XIOM - Math: Roots
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.roots

// Depends on: xiom.math

use xiom.math;

// ============================================================================
// Root extraction and distance (norm) functions (concrete Float64/Int).
// sqrt/cbrt/nth_root delegate to libm math.pow/math.sqrt for speed; the
// *_pure variants are Newton iterations without libm. Even roots of negative
// numbers would produce NaN in IEEE: BUG 19 cannot construct NaN, so a
// documented -1.0 sentinel is returned instead. Integer square/cube roots
// are floor-roots via Newton iteration on Int (no overflow).
// NOTE: requires/ensures clauses are runtime-enforced in this compiler and
// crash on violation, so all domain handling is guarded inside the bodies.
// ============================================================================

/// Principal square root of x. Requires x >= 0. For x < 0 returns NaN
/// (IEEE semantics; BUG 19 fixed 2026-08-11 -- NaN ops now work).
pub fn sqrt(x: Float64) -> Float64
  ensures: result >= 0.0 || result != result
{
  if x < 0.0 { return 0.0 / 0.0; }
  return math.sqrt(x);
}

/// Cube root of x, any sign. Uses sign-split math.pow for speed.
/// cbrt(27.0) == 3.0, cbrt(-27.0) == -3.0. Complexity: O(1), libm pow.
pub fn cbrt(x: Float64) -> Float64 {
  if x == 0.0 { return 0.0; }
  if x > 0.0 { return math.pow(x, 0.3333333333333333); }
  return -math.pow(-x, 0.3333333333333333);
}

/// n-th root of x. For even n, x must be >= 0 (x < 0 returns NaN).
/// For odd n the sign is preserved. n == 0 returns
/// 1.0 (documented: the 0-th root is not defined). Negative n gives
/// x^(1/n) = 1/root. Complexity: O(1), libm pow.
pub fn nth_root(x: Float64, n: Int) -> Float64
  ensures: result >= 0.0 || result != result || n % 2 != 0
{
  if n == 0 { return 1.0; }
  if n == 1 { return x; }
  var inv = 1.0 / (n as Float64);
  if x >= 0.0 { return math.pow(x, inv); }
  if n % 2 == 0 { return 0.0 / 0.0; }
  return -math.pow(-x, inv);
}

/// sqrt via Newton iteration, no libm. Delegates to the proven pure Newton
/// implementation math.sqrt_pure (same algorithm, 50 iterations). For x < 0
/// returns NaN (IEEE semantics). Complexity: O(50).
pub fn sqrt_pure(x: Float64) -> Float64
  ensures: result >= 0.0 || result != result
{
  if x < 0.0 { return 0.0 / 0.0; }
  return math.sqrt_pure(x);
}

/// cbrt via Newton iteration, no libm. 20 iterations with an exponent-scaled
/// initial guess (floor(log2|x|)/3 via math.decompose.ilogb). Exact for all
/// finite values, any sign. Complexity: O(ilogb + 20).
pub fn cbrt_pure(x: Float64) -> Float64 {
  if x == 0.0 { return 0.0; }
  if x == 1.0 / 0.0 { return x; }
  if x == -1.0 / 0.0 { return x; }
  var neg = x < 0.0;
  var ax = x;
  if neg { ax = -ax; }
  var e = math.decompose.ilogb(ax);
  var guess = math.decompose.ldexp(1.0, e / 3);
  var i = 0;
  while i < 20 {
    guess = (2.0 * guess + ax / (guess * guess)) / 3.0;
    i = i + 1;
  }
  if neg { return -guess; }
  return guess;
}

/// True iff n is a perfect square. is_square(0) == true, is_square(16) ==
/// true, is_square(-4) == false. Complexity: O(log sqrt(n)) via integer_sqrt.
pub fn is_square(n: Int) -> Bool {
  if n < 0 { return false; }
  var r = integer_sqrt(n);
  return r * r == n;
}

/// True iff n is a perfect cube. is_cube(0) == true, is_cube(27) == true,
/// is_cube(-27) == false (negative inputs are rejected). Complexity: O(log).
pub fn is_cube(n: Int) -> Bool {
  if n < 0 { return false; }
  var r = integer_cbrt(n);
  return r * r * r == n;
}

/// floor(sqrt(n)) for n >= 0 via integer Newton (no float, no overflow).
/// integer_sqrt(16) == 4, integer_sqrt(17) == 4. For n < 0 returns -1
/// (documented). Complexity: O(log n) iterations.
pub fn integer_sqrt(n: Int) -> Int {
  if n < 0 { return -1; }
  if n < 2 { return n; }
  // x0 = n/2 + 1 >= sqrt(n) for all n >= 1, and x0 + n/x0 never overflows.
  var x = n / 2 + 1;
  while true {
    var next = (x + n / x) / 2;
    if next >= x { return x; }
    x = next;
  }
}

/// floor(cbrt(n)) for n >= 0 via integer Newton (no float, no overflow).
/// integer_cbrt(27) == 3, integer_cbrt(28) == 3. For n < 0 returns -1
/// (documented). Complexity: O(log n) iterations.
pub fn integer_cbrt(n: Int) -> Int {
  if n < 0 { return -1; }
  if n < 2 { return n; }
  var x = 1;
  while x < 2097152 && x * x * x <= n {
    x = x * 2;
  }
  var y = (2 * x + n / (x * x)) / 3;
  while y < x {
    x = y;
    y = (2 * x + n / (x * x)) / 3;
  }
  return x;
}

/// sqrt(x^2 + y^2) without intermediate overflow or underflow. Uses the
/// scaled form m * sqrt(1 + (n/m)^2). hypot(3.0, 4.0) == 5.0.
/// Complexity: O(1), libm sqrt.
pub fn hypot(x: Float64, y: Float64) -> Float64
  ensures: result >= 0.0
{
  var ax = x;
  if ax < 0.0 { ax = -ax; }
  var ay = y;
  if ay < 0.0 { ay = -ay; }
  var m = ax;
  if ay > m { m = ay; }
  var n = ax;
  if ay < n { n = ay; }
  if m == 0.0 { return 0.0; }
  var r = n / m;
  return m * math.sqrt(1.0 + r * r);
}

/// sqrt(x^2 + y^2 + z^2) without intermediate overflow. Generalizes hypot.
/// hypot3(1.0, 2.0, 2.0) == 3.0. Complexity: O(1), libm sqrt.
pub fn hypot3(x: Float64, y: Float64, z: Float64) -> Float64
  ensures: result >= 0.0
{
  var ax = x;
  if ax < 0.0 { ax = -ax; }
  var ay = y;
  if ay < 0.0 { ay = -ay; }
  var az = z;
  if az < 0.0 { az = -az; }
  var m = ax;
  if ay > m { m = ay; }
  if az > m { m = az; }
  if m == 0.0 { return 0.0; }
  var rx = ax / m;
  var ry = ay / m;
  var rz = az / m;
  return m * math.sqrt(rx * rx + ry * ry + rz * rz);
}

/// Euclidean norm of a 2D vector (x, y). Alias of hypot. Complexity: O(1).
pub fn norm2(x: Float64, y: Float64) -> Float64 {
  return hypot(x, y);
}

/// Euclidean norm of a 3D vector (x, y, z). Alias of hypot3. Complexity: O(1).
pub fn norm3(x: Float64, y: Float64, z: Float64) -> Float64 {
  return hypot3(x, y, z);
}
