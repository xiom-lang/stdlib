// XIOM - Math: Transcendental
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.transcendental

// Depends on: none

// ============================================================================
// Exponential, logarithmic, power, and special transcendental functions.
//
// The elementary functions (sqrt/cbrt/exp/exp2/expm1/ln/log2/log10/log1p/
// pow/pow_int/root) delegate to the real xiom.math.roots and
// xiom.math.exponential modules (libm-backed, DRY). The special functions
// (gamma/lgamma via Lanczos, erf/erfc via the Numerical-Recipes continued
// fraction, lambert_w via Newton iteration) are implemented here. IEEE
// special values: NaN = 0.0/0.0, +inf = 1.0/0.0 (BUG 19 fixed). Domain
// errors return NaN; requires/ensures would trap, so domain handling is
// guarded in the bodies.
// ============================================================================

use xiom.math;

// Square root of x; requires x >= 0. Returns NaN (0.0/0.0) for x < 0.
// Delegates to math.roots.sqrt. Complexity: O(1), libm sqrt.
/// Square root of x; requires x >= 0. Returns NaN (0.0/0.0) for x < 0.
/// Delegates to math.roots.sqrt. Complexity: O(1), libm sqrt.
pub fn sqrt(x: Float64) -> Float64 {
  return math.roots.sqrt(x);
}

// Cube root of x, any sign. Delegates to math.roots.cbrt.
// Complexity: O(1), libm pow.
/// Cube root of x, any sign. Delegates to math.roots.cbrt.
/// Complexity: O(1), libm pow.
pub fn cbrt(x: Float64) -> Float64 {
  return math.roots.cbrt(x);
}

// e^x. Returns +inf for x > 700 (overflow) and 0.0 for x < -745
// (underflow). Delegates to math.exponential.exp. Complexity: O(1), libm.
/// e^x. Returns +inf for x > 700 (overflow) and 0.0 for x < -745
/// (underflow). Delegates to math.exponential.exp. Complexity: O(1), libm.
pub fn exp(x: Float64) -> Float64 {
  return math.exponential.exp(x);
}

// 2^x. Delegates to math.exponential.exp2. Complexity: O(1), libm pow.
/// 2^x. Delegates to math.exponential.exp2. Complexity: O(1), libm pow.
pub fn exp2(x: Float64) -> Float64 {
  return math.exponential.exp2(x);
}

// e^x - 1, accurate for small x (series for |x| <= 1e-4). Returns -1.0 for
// x < -700 and +inf for x > 700. Delegates to math.exponential.expm1.
// Complexity: O(20) series terms / O(1) libm.
/// e^x - 1, accurate for small x (series for |x| <= 1e-4). Returns -1.0 for
/// x < -700 and +inf for x > 700. Delegates to math.exponential.expm1.
/// Complexity: O(20) series terms / O(1) libm.
pub fn expm1(x: Float64) -> Float64 {
  return math.exponential.expm1(x);
}

// Natural logarithm of x; requires x > 0. Returns NaN (0.0/0.0) for x <= 0.
// Delegates to math.exponential.ln. Complexity: O(1), libm.
/// Natural logarithm of x; requires x > 0. Returns NaN (0.0/0.0) for x <= 0.
/// Delegates to math.exponential.ln. Complexity: O(1), libm.
pub fn ln(x: Float64) -> Float64 {
  return math.exponential.ln(x);
}

// Base-2 logarithm of x; requires x > 0. Returns NaN for x <= 0.
// Delegates to math.exponential.log2. Complexity: O(1), libm.
/// Base-2 logarithm of x; requires x > 0. Returns NaN for x <= 0.
/// Delegates to math.exponential.log2. Complexity: O(1), libm.
pub fn log2(x: Float64) -> Float64 {
  return math.exponential.log2(x);
}

// Base-10 logarithm of x; requires x > 0. Returns NaN for x <= 0.
// Delegates to math.exponential.log10. Complexity: O(1), libm.
/// Base-10 logarithm of x; requires x > 0. Returns NaN for x <= 0.
/// Delegates to math.exponential.log10. Complexity: O(1), libm.
pub fn log10(x: Float64) -> Float64 {
  return math.exponential.log10(x);
}

// ln(1 + x), accurate for small x (series for |x| <= 1e-4). log1p(-1.0) is
// -inf and log1p(x < -1) returns NaN (IEEE). Delegates to
// math.exponential.log1p. Complexity: O(30) series terms / O(1) libm.
/// ln(1 + x), accurate for small x (series for |x| <= 1e-4). log1p(-1.0) is
/// -inf and log1p(x < -1) returns NaN (IEEE). Delegates to
/// math.exponential.log1p. Complexity: O(30) series terms / O(1) libm.
pub fn log1p(x: Float64) -> Float64 {
  return math.exponential.log1p(x);
}

// a raised to the power b (libm pow). A negative base with a non-integral
// exponent returns NaN (IEEE). Delegates to math.exponential.pow.
// Complexity: O(1), libm.
/// a raised to the power b (libm pow). A negative base with a non-integral
/// exponent returns NaN (IEEE). Delegates to math.exponential.pow.
/// Complexity: O(1), libm.
pub fn pow(a: Float64, b: Float64) -> Float64 {
  return math.exponential.pow(a, b);
}

// a raised to the integer power n via binary exponentiation.
// pow_int(2, 10) == 1024, pow_int(2, -2) == 0.25; 0^0 == 1.0, 0^negative
// == +inf. Delegates to math.exponential.pow_int. Complexity: O(log |n|).
/// a raised to the integer power n via binary exponentiation.
/// pow_int(2, 10) == 1024, pow_int(2, -2) == 0.25; 0^0 == 1.0, 0^negative
/// == +inf. Delegates to math.exponential.pow_int. Complexity: O(log |n|).
pub fn pow_int(a: Float64, n: Int) -> Float64 {
  return math.exponential.pow_int(a, n);
}

// n-th root of x. Even roots require x >= 0 (NaN otherwise); odd roots
// preserve the sign. n == 0 returns 1.0 (documented). Delegates to
// math.roots.nth_root. Complexity: O(1), libm pow.
/// n-th root of x. Even roots require x >= 0 (NaN otherwise); odd roots
/// preserve the sign. n == 0 returns 1.0 (documented). Delegates to
/// math.roots.nth_root. Complexity: O(1), libm pow.
pub fn root(x: Float64, n: Int) -> Float64 {
  return math.roots.nth_root(x, n);
}

// Gamma function via the Lanczos approximation (g = 7, n = 9, error < 2e-10
// for x > 0). gamma(5) == 24, gamma(0.5) == sqrt(pi). Non-positive integer
// arguments are poles and return NaN; other x <= 0 values are handled by the
// reflection formula. Complexity: O(1), ~9 rational terms.
/// Gamma function via the Lanczos approximation (g = 7, n = 9, error < 2e-10
/// for x > 0). gamma(5) == 24, gamma(0.5) == sqrt(pi). Non-positive integer
/// arguments are poles and return NaN; other x <= 0 values are handled by the
/// reflection formula. Complexity: O(1), ~9 rational terms.
pub fn gamma(x: Float64) -> Float64 {
  if x == 1.0 { return 1.0; }
  if x == 2.0 { return 1.0; }
  if x == 0.5 { return math.sqrt(3.14159265358979323846); }
  if x == 1.5 { return math.sqrt(3.14159265358979323846) * 0.5; }
  if x > 0.0 { return _lanczos(x); }
  // x <= 0: poles at non-positive integers, reflection otherwise.
  var ix = math.floor(x);
  if ix == x { return 0.0 / 0.0; }
  var denom = math.sin(math.PI * x);
  if denom == 0.0 { return 0.0 / 0.0; }
  return math.PI / (denom * _lanczos(1.0 - x));
}

// Log-gamma: (ln |gamma(x)|, sign(gamma(x))) with sign in {-1, 1}. Returns
// (NaN, 0) when gamma is a pole (x a non-positive integer). The sign is 1
// for positive values and -1 for negative ones. Complexity: O(gamma).
/// Log-gamma: (ln |gamma(x)|, sign(gamma(x))) with sign in {-1, 1}. Returns
/// (NaN, 0) when gamma is a pole (x a non-positive integer). The sign is 1
/// for positive values and -1 for negative ones. Complexity: O(gamma).
pub fn lgamma(x: Float64) -> (Float64, Int) {
  var g = gamma(x);
  if g != g { return (0.0 / 0.0, 0); }
  if g < 0.0 {
    var lg = math.ln(-g);
    return (lg, -1);
  }
  var lp = math.ln(g);
  return (lp, 1);
}

// Error function erf(x). Uses erfc via the Numerical-Recipes continued
// fraction (relative error < 1.2e-7). erf(0) == 0, erf(1) ~= 0.8427.
// Complexity: O(1).
/// Error function erf(x). Uses erfc via the Numerical-Recipes continued
/// fraction (relative error < 1.2e-7). erf(0) == 0, erf(1) ~= 0.8427.
/// Complexity: O(1).
pub fn erf(x: Float64) -> Float64 {
  return 1.0 - _erfcc(x);
}

// Complementary error function erfc(x) = 1 - erf(x). erfc(0) == 1,
// erfc(3) ~= 2.2e-5. Uses the Numerical-Recipes continued-fraction
// approximation. Complexity: O(1).
/// Complementary error function erfc(x) = 1 - erf(x). erfc(0) == 1,
/// erfc(3) ~= 2.2e-5. Uses the Numerical-Recipes continued-fraction
/// approximation. Complexity: O(1).
pub fn erfc(x: Float64) -> Float64 {
  return _erfcc(x);
}

// Principal (W0) branch of the Lambert W function, the real solution of
// w * e^w = x. lambert_w(0) == 0, lambert_w(e) == 1, lambert_w(1) ~=
// 0.567143. Returns NaN for x < -1/e (no real branch exists). Newton
// iteration on the standard Halley-ish update converges quadratically.
// Complexity: O(100) iterations, O(1) each.
/// Principal (W0) branch of the Lambert W function, the real solution of
/// w * e^w = x. lambert_w(0) == 0, lambert_w(e) == 1, lambert_w(1) ~=
/// 0.567143. Returns NaN for x < -1/e (no real branch exists). Newton
/// iteration on the standard Halley-ish update converges quadratically.
/// Complexity: O(100) iterations, O(1) each.
pub fn lambert_w(x: Float64) -> Float64 {
  if x == 0.0 { return 0.0; }
  if x < -0.36787944117144233 { return 0.0 / 0.0; }
  var w = 0.0;
  if x > 1.0 {
    w = math.ln(x);
  } else {
    w = x * 2.718281828459045;
  }
  var i = 0;
  while i < 100 {
    var ew = math.exp(w);
    var f = w * ew - x;
    if math.abs_float(f) < 1e-15 { return w; }
    var f1 = ew * (w + 1.0);
    var denom2 = 2.0 * w + 2.0;
    if denom2 == 0.0 {
      w = w - f / f1;
    } else {
      var f2 = (w + 2.0) * f / denom2;
      w = w - f / (f1 - f2);
    }
    i = i + 1;
  }
  return w;
}

// ============================================================================
// Internal helpers
// ============================================================================

// Lanczos approximation of gamma(x) for x > 0. O(1), ~9 rational terms.
fn _lanczos(x: Float64) -> Float64 {
  var z = x - 1.0;
  var y = 0.99999999999980993
        + 676.5203681218851 / (z + 1.0)
        - 1259.1392167224028 / (z + 2.0)
        + 771.32342877765313 / (z + 3.0)
        - 176.61502916214059 / (z + 4.0)
        + 12.507343278686905 / (z + 5.0)
        - 0.13857109526572012 / (z + 6.0)
        + 9.9843695780195716e-6 / (z + 7.0)
        + 1.5056327351493116e-7 / (z + 8.0);
  var t = z + 7.5;
  return 2.5066282746310002 * math.pow(t, z + 0.5) * math.exp(-t) * y;
}

// erfc via the Numerical-Recipes continued-fraction approximation.
fn _erfcc(x: Float64) -> Float64 {
  var z = math.abs_float(x);
  var t = 1.0 / (1.0 + 0.5 * z);
  var ans = t * math.exp(-z * z - 1.26551223
    + t * (1.00002368 + t * (0.37409196 + t * (0.09678418
    + t * (-0.18628806 + t * (0.27886807 + t * (-1.13520398
    + t * (1.48851587 + t * (-0.82215223 + t * 0.17087277)))))))));
  if x >= 0.0 { return ans; }
  return 2.0 - ans;
}
