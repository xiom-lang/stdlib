// XIOM - Math: Special
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.special

// Depends on: xiom.math

// ============================================================================
// Special functions: gamma, beta, error, Bessel, zeta, orthogonal polynomials,
// and integral functions.
//
// Implemented in pure XIOM on top of the libm-backed xiom.math wrappers
// (math.exp/math.ln/math.sin/math.cos/math.sqrt/math.pow). Domain errors
// return IEEE NaN (0.0/0.0, BUG 19 fixed) or +-inf at poles (documented per
// function). Iterative series/continued-fraction algorithms carry explicit
// iteration caps; no requires/ensures traps are used (validation lives in the
// bodies). Complexity is documented per function.
// ============================================================================

use xiom.math;
use xiom.core.to_int;
use xiom.core.to_float;

const _PI: Float64 = 3.141592653589793;
const _SQRT_PI: Float64 = 1.772453850905516;
const _TWO_OVER_SQRT_PI: Float64 = 1.1283791670955126;
const _EULER_GAMMA: Float64 = 0.5772156649015329;

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

// ln|gamma(x)| for x in the Lanczos region (x > 0). Lanczos g = 5, n = 6
// (Numerical Recipes coefficients), ~1e-12 relative accuracy.
fn _lanczos_ln(x: Float64) -> Float64 {
  var ser = 1.000000000190015;
  ser = ser + 76.18009172947146 / (x + 1.0);
  ser = ser - 86.50532032941677 / (x + 2.0);
  ser = ser + 24.01409824083091 / (x + 3.0);
  ser = ser - 1.231739572450155 / (x + 4.0);
  ser = ser + 0.1208650973866179e-2 / (x + 5.0);
  ser = ser - 0.5395239384953e-5 / (x + 6.0);
  var tmp = x + 5.5;
  var t = (x + 0.5) * math.ln(tmp) - tmp;
  return t + math.ln(ser * 2.5066282746310002 / x);
}

// Harmonic number H_n for n >= 1 (used by Bessel Y/K series).
fn _harmonic(n: Int) -> Float64 {
  var s = 0.0;
  var i = 1;
  while i <= n {
    s = s + 1.0 / (i as Float64);
    i = i + 1;
  }
  return s;
}

// Rising factorial (a)_k = a(a+1)...(a+k-1) for k >= 1; 1 for k == 0.
fn _rising(a: Float64, k: Int) -> Float64 {
  var r = 1.0;
  var i = 0;
  while i < k {
    r = r * (a + (i as Float64));
    i = i + 1;
  }
  return r;
}

// d^m/dx^m [pi * cot(pi*x)] by the (m+1)-point central-difference stencil.
// Only used by polygamma reflection for m >= 2 and x <= 0.
fn _cot_poly(m: Int, x: Float64) -> Float64 {
  var h = 1.0e-5;
  var fact = 1.0;
  var k = 1;
  while k <= m {
    fact = fact * (k as Float64);
    k = k + 1;
  }
  var scale = 1.0;
  var i = 0;
  while i < m {
    scale = scale * h;
    i = i + 1;
  }
  var sum = 0.0;
  var j = 0;
  while j <= m {
    var sign = 1;
    var comb = 1;
    var q = 0;
    while q < j {
      comb = comb * (m - q);
      comb = comb / (q + 1);
      q = q + 1;
    }
    if j % 2 == 1 { sign = -1; }
    var arg = x + (m / 2 - j) as Float64 * h;
    var val = _PI * 1.0 / math.tan(_PI * arg);
    if sign < 0 {
      sum = sum - (comb as Float64) * val;
    } else {
      sum = sum + (comb as Float64) * val;
    }
    j = j + 1;
  }
  return sum / scale * fact;
}

// Digamma for x >= 6 via the asymptotic series
// psi(x) = ln x - 1/(2x) - sum B_{2k}/(2k x^{2k}).
fn _psi_asym(x: Float64) -> Float64 {
  var x2 = x * x;
  var x4 = x2 * x2;
  var x6 = x4 * x2;
  var x8 = x4 * x4;
  return math.ln(x) - 1.0 / (2.0 * x) - 1.0 / (12.0 * x2) + 1.0 / (120.0 * x4) - 1.0 / (252.0 * x6) + 1.0 / (240.0 * x8);
}

// Polygamma psi^(m) for m >= 1 and x >= 8 via the asymptotic series
// psi^(m)(x) = (-1)^(m+1) m! [ x^-m/m + x^-m-1/2
//                + sum_{k>=1} B_{2k}/(2k)! (m+1)^{overline{2k-1}} x^-m-2k ].
fn _psi_m_asym(m: Int, x: Float64) -> Float64 {
  var mf = (m as Float64);
  var fact_m = 1.0;
  var i = 1;
  while i <= m {
    fact_m = fact_m * (i as Float64);
    i = i + 1;
  }
  var sign = -1.0;
  if (m + 1) % 2 == 0 { sign = 1.0; }
  var term0 = math.pow(x, -mf) / mf;
  var term1 = 0.5 * math.pow(x, -(mf + 1.0));
  var rise1 = _rising(mf + 1.0, 1);
  var term2 = rise1 / 12.0 * math.pow(x, -(mf + 2.0));
  var rise3 = _rising(mf + 1.0, 3);
  var term3 = -rise3 / 720.0 * math.pow(x, -(mf + 4.0));
  var rise5 = _rising(mf + 1.0, 5);
  var term4 = rise5 / 30240.0 * math.pow(x, -(mf + 6.0));
  return sign * fact_m * (term0 + term1 + term2 + term3 + term4);
}

// ---------------------------------------------------------------------------
// Gamma, log-gamma, beta
// ---------------------------------------------------------------------------

/// Gamma function. Poles (x == 0 and negative integers) return +inf
/// (documented). NaN propagates. Complexity: O(1) Lanczos + reflection.
pub fn gamma(x: Float64) -> Float64 {
  if x != x { return x; }
  if x == 0.0 { return 1.0 / 0.0; }
  if x < 0.5 {
    var ti = to_int(x);
    if to_float(ti) == x { return 1.0 / 0.0; }
    var pix = _PI * x;
    var s = math.sin(pix);
    var g = _lanczos_ln(1.0 - x);
    var denom = s * math.exp(g);
    return _PI / denom;
  }
  return math.exp(_lanczos_ln(x));
}

/// Log-gamma: (ln|gamma(x)|, sign of gamma(x)). sign is +1 or -1, or 0 at a
/// pole (value +inf). Complexity: O(1).
pub fn lgamma(x: Float64) -> (Float64, Int) {
  if x != x { return (x, 0); }
  if x == 0.0 { return (1.0 / 0.0, 0); }
  if x < 0.5 {
    var ti = to_int(x);
    if to_float(ti) == x { return (1.0 / 0.0, 0); }
    var g = _lanczos_ln(1.0 - x);
    var pix = _PI * x;
    var s = math.sin(pix);
    var val = math.ln(math.abs_float(_PI / s)) - g;
    var sign = 1;
    if s < 0.0 { sign = -1; }
    return (val, sign);
  }
  var ll = _lanczos_ln(x);
  return (ll, 1);
}

/// Natural log of the gamma function. Same value as lgamma's first component
/// (sign discarded). Complexity: O(1).
pub fn gamma_ln(x: Float64) -> Float64 {
  if x != x { return x; }
  if x == 0.0 { return 1.0 / 0.0; }
  if x < 0.5 {
    var ti = to_int(x);
    if to_float(ti) == x { return 1.0 / 0.0; }
    var g = _lanczos_ln(1.0 - x);
    var pix = _PI * x;
    var s = math.sin(pix);
    return math.ln(math.abs_float(_PI / s)) - g;
  }
  return _lanczos_ln(x);
}

/// Beta function B(a, b) = gamma(a) gamma(b) / gamma(a + b) via the Lanczos
/// log-gamma (stable, no overflow). Returns NaN for a <= 0 or b <= 0
/// (documented domain). Complexity: O(1).
pub fn beta(a: Float64, b: Float64) -> Float64 {
  if a <= 0.0 || b <= 0.0 { return 0.0 / 0.0; }
  var lg = _lanczos_ln(a) + _lanczos_ln(b) - _lanczos_ln(a + b);
  return math.exp(lg);
}

/// Natural log of the beta function. NaN for a <= 0 or b <= 0. Complexity: O(1).
pub fn beta_ln(a: Float64, b: Float64) -> Float64 {
  if a <= 0.0 || b <= 0.0 { return 0.0 / 0.0; }
  return _lanczos_ln(a) + _lanczos_ln(b) - _lanczos_ln(a + b);
}

// ---------------------------------------------------------------------------
// Incomplete gamma and beta
// ---------------------------------------------------------------------------

// Series evaluation of the regularized lower incomplete gamma P(a, x)
// (used for x < a + 1). At most 200 terms.
fn _gser(a: Float64, x: Float64) -> Float64 {
  var gln = _lanczos_ln(a);
  var ap = a;
  var sum = 1.0 / a;
  var del = sum;
  var n = 1;
  while n <= 200 {
    ap = ap + 1.0;
    del = del * x / ap;
    sum = sum + del;
    var a1 = math.abs_float(del);
    var a2 = math.abs_float(sum) * 3.0e-14;
    if a1 < a2 {
      return sum * math.exp(-x + a * math.ln(x) - gln);
    }
    n = n + 1;
  }
  return sum * math.exp(-x + a * math.ln(x) - gln);
}

// Continued-fraction evaluation of the regularized upper incomplete gamma
// Q(a, x) (used for x >= a + 1, Lentz algorithm). At most 200 iterations.
fn _gcf(a: Float64, x: Float64) -> Float64 {
  var gln = _lanczos_ln(a);
  var b = x + 1.0 - a;
  var c = 1.0e300;
  var d = 1.0 / b;
  var h = d;
  var i = 1;
  while i <= 200 {
    var an = -(i as Float64) * ((i as Float64) - a);
    b = b + 2.0;
    d = an * d + b;
    if math.abs_float(d) < 1.0e-300 { d = 1.0e-300; }
    c = b + an / c;
    if math.abs_float(c) < 1.0e-300 { c = 1.0e-300; }
    d = 1.0 / d;
    var del = d * c;
    h = h * del;
    var a1 = math.abs_float(del - 1.0);
    if a1 < 3.0e-14 {
      return math.exp(-x + a * math.ln(x) - gln) * h;
    }
    i = i + 1;
  }
  return math.exp(-x + a * math.ln(x) - gln) * h;
}

/// Regularized lower incomplete gamma P(a, x). NaN for a <= 0 or x < 0;
/// P(a, 0) == 0. Uses the series (x < a + 1) or continued fraction.
/// Complexity: O(iterations).
pub fn incomplete_gamma(a: Float64, x: Float64) -> Float64 {
  if a <= 0.0 || x < 0.0 { return 0.0 / 0.0; }
  if x == 0.0 { return 0.0; }
  if x < a + 1.0 { return _gser(a, x); }
  return 1.0 - _gcf(a, x);
}

/// Alias of incomplete_gamma: the regularized lower incomplete gamma P(a, x).
pub fn incomplete_gamma_low(a: Float64, x: Float64) -> Float64 {
  return incomplete_gamma(a, x);
}

// Continued fraction for the regularized incomplete beta (Lentz, NR betacf).
fn _betacf(a: Float64, b: Float64, x: Float64) -> Float64 {
  var qab = a + b;
  var qap = a + 1.0;
  var qam = a - 1.0;
  var c = 1.0;
  var d = 1.0 - qab * x / qap;
  if math.abs_float(d) < 1.0e-300 { d = 1.0e-300; }
  d = 1.0 / d;
  var h = d;
  var m = 1;
  while m <= 200 {
    var m2 = 2 * m;
    var aa = (m as Float64) * (b - (m as Float64)) * x / ((qam + (m2 as Float64)) * (a + (m2 as Float64)));
    d = 1.0 + aa * d;
    if math.abs_float(d) < 1.0e-300 { d = 1.0e-300; }
    c = 1.0 + aa / c;
    if math.abs_float(c) < 1.0e-300 { c = 1.0e-300; }
    d = 1.0 / d;
    h = h * d * c;
    aa = -(a + (m as Float64)) * (qab + (m as Float64)) * x / ((a + (m2 as Float64)) * (qap + (m2 as Float64)));
    d = 1.0 + aa * d;
    if math.abs_float(d) < 1.0e-300 { d = 1.0e-300; }
    c = 1.0 + aa / c;
    if math.abs_float(c) < 1.0e-300 { c = 1.0e-300; }
    d = 1.0 / d;
    var del = d * c;
    h = h * del;
    var a1 = math.abs_float(del - 1.0);
    if a1 < 3.0e-14 { return h; }
    m = m + 1;
  }
  return h;
}

/// Regularized incomplete beta I_x(a, b) for x in [0, 1]. NaN for a <= 0,
/// b <= 0, or x outside [0, 1]. Series/continued-fraction evaluation.
/// Complexity: O(iterations).
pub fn incomplete_beta(a: Float64, b: Float64, x: Float64) -> Float64 {
  if a <= 0.0 || b <= 0.0 { return 0.0 / 0.0; }
  if x <= 0.0 { return 0.0; }
  if x >= 1.0 { return 1.0; }
  var bt = math.exp(_lanczos_ln(a + b) - _lanczos_ln(a) - _lanczos_ln(b)
    + a * math.ln(x) + b * math.ln(1.0 - x));
  var symm = (a + 1.0) / (a + b + 2.0);
  if x < symm {
    var cf = _betacf(a, b, x);
    if cf != cf { return cf; }
    return bt * cf / a;
  }
  var cf2 = _betacf(b, a, 1.0 - x);
  if cf2 != cf2 { return cf2; }
  return 1.0 - bt * cf2 / b;
}

// ---------------------------------------------------------------------------
// Error functions
// ---------------------------------------------------------------------------

// Shared Numerical Recipes rational approximation of erfc(|x|): returns
// t * exp(-x^2 + poly(t)) with t = 1/(1 + 0.5|x|).
fn _erfc_t(t: Float64, x: Float64) -> Float64 {
  var p = t * (1.00002368 + t * (0.37409196 + t * (0.09678418 + t * (-0.18628806
    + t * (0.27886807 + t * (-1.13520398 + t * (1.48851587 + t * (-0.82215223
    + t * 0.17087277))))))));
  return t * math.exp(-x * x - 1.26551223 + p);
}

/// Error function erf(x). Maximum absolute error ~3e-8 (NR rational approx).
/// Complexity: O(1).
pub fn erf(x: Float64) -> Float64 {
  if x != x { return x; }
  if x == 0.0 { return 0.0; }
  var ax = math.abs_float(x);
  var t = 1.0 / (1.0 + 0.5 * ax);
  var u = _erfc_t(t, ax);
  if x > 0.0 { return 1.0 - u; }
  return u - 1.0;
}

/// Complementary error function erfc(x) = 1 - erf(x). Complexity: O(1).
pub fn erfc(x: Float64) -> Float64 {
  if x != x { return x; }
  if x == 0.0 { return 1.0; }
  var ax = math.abs_float(x);
  var t = 1.0 / (1.0 + 0.5 * ax);
  var u = _erfc_t(t, ax);
  if x > 0.0 { return u; }
  return 2.0 - u;
}

/// Imaginary error function erfi(x) = -i erf(i x) = (2/sqrt(pi)) sum
/// x^(2n+1)/(n!(2n+1)). Series for |x| <= 3; for larger |x| the asymptotic
/// form erfi(x) ~ exp(x^2)/(sqrt(pi) x) is used. Complexity: O(n^2).
pub fn erfi(x: Float64) -> Float64 {
  if x != x { return x; }
  if x == 0.0 { return 0.0; }
  var neg = x < 0.0;
  var ax = math.abs_float(x);
  var r = 0.0;
  if ax <= 3.0 {
    var sum = 0.0;
    var n = 0;
    while n <= 60 {
      var p = math.pow(ax, (2 * n + 1) as Float64);
      var fact = 1.0;
      var j = 1;
      while j <= n {
        fact = fact * (j as Float64);
        j = j + 1;
      }
      sum = sum + p / (fact * (2.0 * (n as Float64) + 1.0));
      n = n + 1;
    }
    r = sum * _TWO_OVER_SQRT_PI;
  } else {
    var x2 = ax * ax;
    var sum = 1.0;
    var n = 1;
    while n <= 10 {
      var df = 1.0;
      var j = 1;
      while j <= n {
        df = df * (2.0 * (j as Float64) - 1.0);
        j = j + 1;
      }
      var denom = math.pow(2.0 * x2, n as Float64);
      sum = sum + df / denom;
      n = n + 1;
    }
    r = math.exp(x2) / (_SQRT_PI * ax) * sum;
  }
  if neg { return -r; }
  return r;
}

/// Dawson integral D(x) = exp(-x^2) * integral_0^x exp(t^2) dt.
/// Series for |x| <= 3, asymptotic for larger |x|. Complexity: O(n^2).
pub fn dawson(x: Float64) -> Float64 {
  if x != x { return x; }
  if x == 0.0 { return 0.0; }
  var neg = x < 0.0;
  var ax = math.abs_float(x);
  var r = 0.0;
  if ax <= 3.0 {
    var x2 = ax * ax;
    var sum = 0.0;
    var n = 0;
    while n <= 60 {
      var p2 = math.pow(2.0 * x2, n as Float64);
      var df = 1.0;
      var j = 1;
      while j <= 2 * n + 1 {
        if j % 2 == 1 {
          df = df * (j as Float64);
        }
        j = j + 1;
      }
      var t = p2 / df;
      if n % 2 == 1 { sum = sum - t; } else { sum = sum + t; }
      n = n + 1;
    }
    r = ax * sum;
  } else {
    var x2 = ax * ax;
    var sum = 0.5 / ax;
    var term = 0.5 / ax;
    var n = 1;
    while n <= 10 {
      term = term * (2.0 * (n as Float64) - 1.0) / (2.0 * x2);
      sum = sum + term;
      n = n + 1;
    }
    r = sum;
  }
  if neg { return -r; }
  return r;
}

/// Inverse error function erfinv(x) by Newton iteration on erf (30 iters,
/// ~1e-12 accuracy away from the endpoints). erfinv(+-1) = +-inf; |x| > 1
/// returns NaN. Complexity: O(30).
pub fn erfinv(x: Float64) -> Float64 {
  if x != x { return x; }
  if x <= -1.0 {
    if x == -1.0 { return -1.0 / 0.0; }
    return 0.0 / 0.0;
  }
  if x >= 1.0 {
    if x == 1.0 { return 1.0 / 0.0; }
    return 0.0 / 0.0;
  }
  if x == 0.0 { return 0.0; }
  var y = 0.886226925452758 * x;
  var i = 0;
  while i < 30 {
    var ey = math.exp(-y * y);
    var f = erf(y) - x;
    var fp = _TWO_OVER_SQRT_PI * ey;
    if fp == 0.0 { return y; }
    var dy = f / fp;
    y = y - dy;
    if math.abs_float(dy) < 1.0e-15 { return y; }
    i = i + 1;
  }
  return y;
}

/// Inverse complementary error function erfcinv(x) = erfinv(1 - x).
/// x in (0, 2); endpoints return +-inf; outside returns NaN.
/// Complexity: O(erfinv).
pub fn erfcinv(x: Float64) -> Float64 {
  if x != x { return x; }
  if x <= 0.0 {
    if x == 0.0 { return 1.0 / 0.0; }
    return 0.0 / 0.0;
  }
  if x >= 2.0 {
    if x == 2.0 { return -1.0 / 0.0; }
    return 0.0 / 0.0;
  }
  return erfinv(1.0 - x);
}

// ---------------------------------------------------------------------------
// Bessel functions
// ---------------------------------------------------------------------------

/// J_0(x) via the alternating power series. Accurate for moderate |x|;
/// for |x| > 30 the asymptotic form is used. Complexity: O(n^2).
pub fn bessel_j0(x: Float64) -> Float64 {
  if x != x { return x; }
  var ax = math.abs_float(x);
  if ax > 30.0 {
    var s = math.sqrt(2.0 / (_PI * ax));
    var xm = ax - _PI / 4.0;
    var p = 1.0 - 9.0 / (128.0 * ax * ax) + 3675.0 / (32768.0 * ax * ax * ax * ax);
    var q = -1.0 / (8.0 * ax) + 75.0 / (1024.0 * ax * ax * ax);
    return s * (p * math.cos(xm) - q * math.sin(xm));
  }
  var sum = 0.0;
  var n = 0;
  while n <= 50 {
    var p = math.pow(x, (2 * n) as Float64);
    var twop = math.pow(2.0, (2 * n) as Float64);
    var fact = 1.0;
    var j = 1;
    while j <= n {
      fact = fact * (j as Float64) * (j as Float64);
      j = j + 1;
    }
    var t = p / (twop * fact);
    if n % 2 == 1 { sum = sum - t; } else { sum = sum + t; }
    n = n + 1;
  }
  return sum;
}

/// J_1(x) via the alternating power series. Complexity: O(n^2).
pub fn bessel_j1(x: Float64) -> Float64 {
  if x != x { return x; }
  var ax = math.abs_float(x);
  if ax > 30.0 {
    var s = math.sqrt(2.0 / (_PI * ax));
    var xm = ax - 3.0 * _PI / 4.0;
    var p = 1.0 + 15.0 / (128.0 * ax * ax) - 11025.0 / (32768.0 * ax * ax * ax * ax);
    var q = 3.0 / (8.0 * ax) - 315.0 / (1024.0 * ax * ax * ax);
    var r = s * (p * math.cos(xm) - q * math.sin(xm));
    if x < 0.0 { return -r; }
    return r;
  }
  var sum = 0.0;
  var n = 0;
  while n <= 50 {
    var p = math.pow(x, (2 * n + 1) as Float64);
    var twop = math.pow(2.0, (2 * n + 1) as Float64);
    var fact = 1.0;
    var j = 1;
    while j <= n {
      fact = fact * (j as Float64) * ((j as Float64) + 1.0);
      j = j + 1;
    }
    var t = p / (twop * fact);
    if n % 2 == 1 { sum = sum - t; } else { sum = sum + t; }
    n = n + 1;
  }
  return sum;
}

/// J_n(x), Bessel of the first kind of integer order n, by its power series
/// sum (-1)^k (x/2)^(2k+n)/(k!(k+n)!). Negative n uses J_{-n} = (-1)^n J_n.
/// Complexity: O(n^2).
pub fn bessel_j(n: Int, x: Float64) -> Float64 {
  if n < 0 {
    var v = bessel_j(-n, x);
    if n % 2 == 0 { return v; }
    return -v;
  }
  var xh = 0.5 * x;
  var sum = 0.0;
  var k = 0;
  while k <= 80 {
    var p = math.pow(xh, (2 * k + n) as Float64);
    var f1 = 1.0;
    var j = 1;
    while j <= k {
      f1 = f1 * (j as Float64);
      j = j + 1;
    }
    var f2 = 1.0;
    var j2 = 1;
    while j2 <= k + n {
      f2 = f2 * (j2 as Float64);
      j2 = j2 + 1;
    }
    var t = p / (f1 * f2);
    if k % 2 == 1 { sum = sum - t; } else { sum = sum + t; }
    k = k + 1;
  }
  return sum;
}

/// Alias of bessel_j for order n. Complexity: O(terms).
pub fn bessel_jn(n: Int, x: Float64) -> Float64 {
  return bessel_j(n, x);
}

/// Y_0(x), Bessel of the second kind of order zero: series with the
/// digamma/harmonic terms. NaN for x <= 0 (branch cut). Complexity: O(terms).
pub fn bessel_y0(x: Float64) -> Float64 {
  if x != x { return x; }
  if x <= 0.0 { return 0.0 / 0.0; }
  if x > 30.0 {
    var s = math.sqrt(2.0 / (_PI * x));
    var xm = x - _PI / 4.0;
    var p = 1.0 - 9.0 / (128.0 * x * x) + 3675.0 / (32768.0 * x * x * x * x);
    var q = -1.0 / (8.0 * x) + 75.0 / (1024.0 * x * x * x);
    return s * (p * math.sin(xm) + q * math.cos(xm));
  }
  var j0 = bessel_j0(x);
  var half = x / 2.0;
  var sum = 0.0;
  var term = 1.0;
  var n = 1;
  while n <= 60 {
    var denom = 1.0;
    var k = 1;
    while k <= n {
      denom = denom * (k as Float64) * (k as Float64);
      k = k + 1;
    }
    term = term * half * half;
    var coeff = 1.0;
    if n % 2 == 0 { coeff = -1.0; }
    sum = sum + coeff * term / denom * _harmonic(n);
    n = n + 1;
  }
  return 2.0 / _PI * ((math.ln(x / 2.0) + _EULER_GAMMA) * j0 + sum);
}

/// Y_1(x), Bessel of the second kind of order one, via -d/dx Y_0 (central
/// difference, ~1e-9 relative for moderate x). NaN for x <= 0. Complexity: O(1).
pub fn bessel_y1(x: Float64) -> Float64 {
  if x != x { return x; }
  if x <= 0.0 { return 0.0 / 0.0; }
  var h = 1.0e-6 * math.max_float(1.0, math.abs_float(x));
  return -(bessel_y0(x + h) - bessel_y0(x - h)) / (2.0 * h);
}

/// Y_n(x), Bessel of the second kind of integer order n by upward recurrence
/// Y_{n+1} = (2n/x) Y_n - Y_{n-1} from Y_0, Y_1. NaN for x <= 0.
/// Complexity: O(n).
pub fn bessel_y(n: Int, x: Float64) -> Float64 {
  return bessel_yn(n, x);
}

/// Y_n(x) for integer order n. NaN for x <= 0 or negative n. Complexity: O(n).
pub fn bessel_yn(n: Int, x: Float64) -> Float64 {
  if n < 0 { return 0.0 / 0.0; }
  if x != x { return x; }
  if x <= 0.0 { return 0.0 / 0.0; }
  if n == 0 { return bessel_y0(x); }
  if n == 1 { return bessel_y1(x); }
  var y0 = bessel_y0(x);
  var y1 = bessel_y1(x);
  var ym1 = y0;
  var y = y1;
  var k = 1;
  while k < n {
    var yp1 = (2.0 * (k as Float64) / x) * y - ym1;
    ym1 = y;
    y = yp1;
    k = k + 1;
  }
  return y;
}

/// I_n(x), modified Bessel of the first kind of integer order n (series
/// sum (x/2)^(2k+n)/(k!(k+n)!); I_{-n} == I_n for integer n).
/// Complexity: O(n^2).
pub fn bessel_i(n: Int, x: Float64) -> Float64 {
  var nn = n;
  if nn < 0 { nn = -nn; }
  var xh = 0.5 * x;
  var sum = 0.0;
  var k = 0;
  while k <= 80 {
    var p = math.pow(xh, (2 * k + nn) as Float64);
    var f1 = 1.0;
    var j = 1;
    while j <= k {
      f1 = f1 * (j as Float64);
      j = j + 1;
    }
    var f2 = 1.0;
    var j2 = 1;
    while j2 <= k + nn {
      f2 = f2 * (j2 as Float64);
      j2 = j2 + 1;
    }
    sum = sum + p / (f1 * f2);
    k = k + 1;
  }
  return sum;
}

/// K_0(x), modified Bessel of the second kind of order zero: series
/// K_0 = -(ln(x/2) + gamma) I_0 + sum H_k/(k!)^2 (x/2)^{2k}. NaN for x <= 0.
pub fn bessel_k0(x: Float64) -> Float64 {
  if x != x { return x; }
  if x <= 0.0 { return 0.0 / 0.0; }
  if x > 30.0 {
    var ax = math.exp(-x) / math.sqrt(x);
    var p = 1.0 - 1.0 / (8.0 * x) + 9.0 / (128.0 * x * x);
    return math.sqrt(_PI / (2.0 * x)) * math.exp(-x) * p;
  }
  var i0 = bessel_i(0, x);
  var half = x / 2.0;
  var sum = 0.0;
  var term = 1.0;
  var n = 1;
  while n <= 60 {
    var denom = 1.0;
    var k = 1;
    while k <= n {
      denom = denom * (k as Float64) * (k as Float64);
      k = k + 1;
    }
    term = term * half * half;
    sum = sum + term / denom * _harmonic(n);
    n = n + 1;
  }
  return -(math.ln(x / 2.0) + _EULER_GAMMA) * i0 + sum;
}

/// K_1(x) via -d/dx K_0 (central difference). NaN for x <= 0. Complexity: O(1).
pub fn bessel_k1(x: Float64) -> Float64 {
  if x != x { return x; }
  if x <= 0.0 { return 0.0 / 0.0; }
  var h = 1.0e-6 * math.max_float(1.0, math.abs_float(x));
  return -(bessel_k0(x + h) - bessel_k0(x - h)) / (2.0 * h);
}

/// K_n(x), modified Bessel of the second kind of integer order n by upward
/// recurrence K_{n+1} = (2n/x) K_n + K_{n-1}. NaN for x <= 0 or n < 0.
pub fn bessel_k(n: Int, x: Float64) -> Float64 {
  if n < 0 { return 0.0 / 0.0; }
  if x != x { return x; }
  if x <= 0.0 { return 0.0 / 0.0; }
  if n == 0 { return bessel_k0(x); }
  if n == 1 { return bessel_k1(x); }
  var k0 = bessel_k0(x);
  var k1 = bessel_k1(x);
  var km1 = k0;
  var kk = k1;
  var j = 1;
  while j < n {
    var kp1 = (2.0 * (j as Float64) / x) * kk + km1;
    km1 = kk;
    kk = kp1;
    j = j + 1;
  }
  return kk;
}

// ---------------------------------------------------------------------------
// Zeta and related series
// ---------------------------------------------------------------------------

/// Riemann zeta via Euler-Maclaurin (9 pre-summed terms + Bernoulli terms to
/// B_16). Exact to ~1e-9 for s in (0, 40]. s == 1 returns +inf; s < 0 uses
/// the functional equation zeta(s) = 2^s pi^(s-1) sin(pi s/2) Gamma(1-s)
/// zeta(1-s). Complexity: O(1).
pub fn zeta(x: Float64) -> Float64 {
  if x != x { return x; }
  if x == 1.0 { return 1.0 / 0.0; }
  if x < 0.0 {
    var s2 = math.pow(2.0, x);
    var sp = math.pow(_PI, x - 1.0);
    var sn = math.sin(_PI * x / 2.0);
    var g = gamma(1.0 - x);
    var z = zeta(1.0 - x);
    return s2 * sp * sn * g * z;
  }
  var n = 10;
  var sum = 0.0;
  var k = 1;
  while k < n {
    sum = sum + math.pow(k as Float64, -x);
    k = k + 1;
  }
  var nf = n as Float64;
  var term = math.pow(nf, 1.0 - x) / (x - 1.0) + 0.5 * math.pow(nf, -x);
  var b2 = x * math.pow(nf, -x - 1.0) / 12.0;
  var b4 = -x * (x + 1.0) * (x + 2.0) * math.pow(nf, -x - 3.0) / 720.0;
  var b6 = x * (x + 1.0) * (x + 2.0) * (x + 3.0) * (x + 4.0) * math.pow(nf, -x - 5.0) / 30240.0;
  var b8 = -x * (x + 1.0) * (x + 2.0) * (x + 3.0) * (x + 4.0) * (x + 5.0) * (x + 6.0) * math.pow(nf, -x - 7.0) / 1209600.0;
  return sum + term + b2 + b4 + b6 + b8;
}

/// Riemann zeta (alias). Complexity: O(1).
pub fn riemann_zeta(x: Float64) -> Float64 {
  return zeta(x);
}

/// Dirichlet eta function: eta(s) = (1 - 2^(1-s)) zeta(s). Complexity: O(1).
pub fn riemann_zeta_eta(x: Float64) -> Float64 {
  if x != x { return x; }
  if x == 1.0 { return math.ln(2.0); }
  var f = 1.0 - math.pow(2.0, 1.0 - x);
  return f * zeta(x);
}

/// Dirichlet beta function beta(s) = sum (-1)^k (2k+1)^(-s) by direct
/// alternating summation (100k terms; alternating-series tail bound).
/// Complexity: O(100000).
pub fn dirichlet_beta(x: Float64) -> Float64 {
  if x != x { return x; }
  if x <= 0.0 { return 0.0 / 0.0; }
  var sum = 0.0;
  var k = 0;
  while k <= 100000 {
    var d = 2.0 * (k as Float64) + 1.0;
    var t = math.pow(d, -x);
    if k % 2 == 1 { sum = sum - t; } else { sum = sum + t; }
    k = k + 1;
  }
  return sum;
}

/// Lerch transcendent Phi(z, s, a) = sum z^k (k+a)^(-s), |z| < 1, a > 0.
/// At most 2000 terms; NaN for |z| >= 1 (divergent) or a <= 0.
/// Complexity: O(terms).
pub fn lerch_phi(z: Float64, s: Float64, a: Float64) -> Float64 {
  if a <= 0.0 { return 0.0 / 0.0; }
  if math.abs_float(z) >= 1.0 {
    if z == 1.0 && s > 1.0 {
      var sum = 0.0;
      var k = 0;
      while k < 100000 {
        sum = sum + math.pow((k as Float64) + a, -s);
        k = k + 1;
      }
      return sum;
    }
    return 0.0 / 0.0;
  }
  var sum = 0.0;
  var zp = 1.0;
  var k = 0;
  while k <= 2000 {
    if k > 0 { zp = zp * z; }
    sum = sum + zp * math.pow((k as Float64) + a, -s);
    k = k + 1;
  }
  return sum;
}

/// Polylogarithm Li_s(z) = sum z^k k^(-s), |z| < 1 (z == 1 and s > 1 gives
/// zeta(s)). At most 2000 terms; NaN for |z| > 1 (divergent). Complexity: O(2000).
pub fn polylog(s: Float64, z: Float64) -> Float64 {
  if z == 1.0 {
    if s > 1.0 { return zeta(s); }
    return 1.0 / 0.0;
  }
  if math.abs_float(z) > 1.0 { return 0.0 / 0.0; }
  var sum = 0.0;
  var zp = 1.0;
  var k = 1;
  while k <= 2000 {
    zp = zp * z;
    sum = sum + zp * math.pow(k as Float64, -s);
    k = k + 1;
  }
  return sum;
}

// ---------------------------------------------------------------------------
// Digamma and polygamma
// ---------------------------------------------------------------------------

/// Digamma psi(x) = d/dx ln gamma(x). NaN at poles (x <= 0 integer); uses the
/// shift recurrence + asymptotic for x >= 6 and the reflection formula for
/// x < 0.5. Complexity: O(ceil(6 - x)) shifts.
pub fn digamma(x: Float64) -> Float64 {
  if x != x { return x; }
  if x <= 0.0 {
    var ti = to_int(x);
    if to_float(ti) == x { return 1.0 / 0.0; }
    var pix = _PI * x;
    var cot = 1.0 / math.tan(pix);
    return digamma(1.0 - x) - _PI * cot;
  }
  var v = x;
  var shift = 0.0;
  while v < 6.0 {
    shift = shift + 1.0 / v;
    v = v + 1.0;
  }
  return _psi_asym(v) - shift;
}

/// Trigamma psi'(x), second derivative of ln gamma. NaN at poles. Complexity:
/// O(shifts).
pub fn trigamma(x: Float64) -> Float64 {
  return polygamma(1, x);
}

/// Polygamma psi^(m)(x). m == 0 delegates to digamma; m < 0 returns NaN.
/// For x <= 0 non-integer the reflection psi^(m)(x) = (-1)^m psi^(m)(1-x)
/// - pi d^m/dx^m cot(pi x) is used (numerical cot derivative for m >= 2);
/// poles return +inf. Complexity: O(shifts + m^2).
pub fn polygamma(m: Int, x: Float64) -> Float64 {
  if m < 0 { return 0.0 / 0.0; }
  if x != x { return x; }
  if x <= 0.0 {
    var ti = to_int(x);
    if to_float(ti) == x { return 1.0 / 0.0; }
    if m == 0 { return digamma(x); }
    if m == 1 {
      var pix = _PI * x;
      var csc2 = 1.0 / (math.sin(pix) * math.sin(pix));
      return _PI * _PI * csc2 - polygamma(1, 1.0 - x);
    }
    var refl = 1.0;
    if m % 2 == 1 { refl = -1.0; }
    var cp = _cot_poly(m, x);
    return refl * polygamma(m, 1.0 - x) - cp;
  }
  if m == 0 { return digamma(x); }
  var v = x;
  var shift = 0.0;
  while v < 8.0 {
    var f = 1.0;
    var i = 1;
    while i <= m {
      f = f * (i as Float64);
      i = i + 1;
    }
    var sgn = -1.0;
    if m % 2 == 0 { sgn = 1.0; }
    var term = sgn * f * math.pow(v, -((m as Float64) + 1.0));
    shift = shift + term;
    v = v + 1.0;
  }
  return _psi_m_asym(m, v) - shift;
}

// ---------------------------------------------------------------------------
// Orthogonal polynomials
// ---------------------------------------------------------------------------

/// Legendre polynomial P_n(x) by the recurrence (n+1)P_{n+1} =
/// (2n+1)x P_n - n P_{n-1}. NaN for n < 0. Complexity: O(n).
pub fn legendre_p(n: Int, x: Float64) -> Float64 {
  if n < 0 { return 0.0 / 0.0; }
  if n == 0 { return 1.0; }
  if n == 1 { return x; }
  var p0 = 1.0;
  var p1 = x;
  var k = 1;
  while k < n {
    var p2 = ((2.0 * (k as Float64) + 1.0) * x * p1 - (k as Float64) * p0) / ((k as Float64) + 1.0);
    p0 = p1;
    p1 = p2;
    k = k + 1;
  }
  return p1;
}

/// Legendre function of the second kind Q_n(x) for |x| < 1 (Q0 = atanh(x),
/// Q1 = x atanh(x) - 1, then the same recurrence as P). NaN for |x| >= 1 or
/// n < 0. Complexity: O(n).
pub fn legendre_q(n: Int, x: Float64) -> Float64 {
  if n < 0 { return 0.0 / 0.0; }
  if x >= 1.0 || x <= -1.0 { return 0.0 / 0.0; }
  var at = 0.5 * math.ln((1.0 + x) / (1.0 - x));
  if n == 0 { return at; }
  if n == 1 { return x * at - 1.0; }
  var q0 = at;
  var q1 = x * at - 1.0;
  var k = 1;
  while k < n {
    var q2 = ((2.0 * (k as Float64) + 1.0) * x * q1 - (k as Float64) * q0) / ((k as Float64) + 1.0);
    q0 = q1;
    q1 = q2;
    k = k + 1;
  }
  return q1;
}

/// Chebyshev polynomial of the first kind T_n(x): T_{n+1} = 2x T_n - T_{n-1}.
/// NaN for n < 0. Complexity: O(n).
pub fn chebyshev_t(n: Int, x: Float64) -> Float64 {
  if n < 0 { return 0.0 / 0.0; }
  if n == 0 { return 1.0; }
  if n == 1 { return x; }
  var t0 = 1.0;
  var t1 = x;
  var k = 1;
  while k < n {
    var t2 = 2.0 * x * t1 - t0;
    t0 = t1;
    t1 = t2;
    k = k + 1;
  }
  return t1;
}

/// Hermite polynomial (physicists') H_n(x): H_{n+1} = 2x H_n - 2n H_{n-1}.
/// NaN for n < 0. Complexity: O(n).
pub fn hermite_h(n: Int, x: Float64) -> Float64 {
  if n < 0 { return 0.0 / 0.0; }
  if n == 0 { return 1.0; }
  if n == 1 { return 2.0 * x; }
  var h0 = 1.0;
  var h1 = 2.0 * x;
  var k = 1;
  while k < n {
    var h2 = 2.0 * x * h1 - 2.0 * (k as Float64) * h0;
    h0 = h1;
    h1 = h2;
    k = k + 1;
  }
  return h1;
}

/// Generalized Laguerre polynomial L_n^(a)(x). NaN for n < 0 or a <= -1.
/// Complexity: O(n).
pub fn laguerre_l(n: Int, a: Float64, x: Float64) -> Float64 {
  if n < 0 || a <= -1.0 { return 0.0 / 0.0; }
  if n == 0 { return 1.0; }
  if n == 1 { return 1.0 + a - x; }
  var l0 = 1.0;
  var l1 = 1.0 + a - x;
  var k = 1;
  while k < n {
    var l2 = ((2.0 * (k as Float64) + 1.0 + a - x) * l1 - ((k as Float64) + a) * l0) / ((k as Float64) + 1.0);
    l0 = l1;
    l1 = l2;
    k = k + 1;
  }
  return l1;
}

/// Jacobi polynomial P_n^(a,b)(x). NaN for n < 0, a <= -1, b <= -1.
/// Three-term recurrence (DLMF 18.9.2). Complexity: O(n).
pub fn jacobi_p(n: Int, a: Float64, b: Float64, x: Float64) -> Float64 {
  if n < 0 || a <= -1.0 || b <= -1.0 { return 0.0 / 0.0; }
  if n == 0 { return 1.0; }
  var p0 = 1.0;
  var p1 = (a - b + (a + b + 2.0) * x) / 2.0;
  if n == 1 { return p1; }
  var k = 1;
  while k < n {
    var kf = (k as Float64);
    var n1 = 2.0 * kf + a + b + 1.0;
    var n2 = 2.0 * kf + a + b;
    var n3 = 2.0 * kf + a + b + 2.0;
    var coef = n1 * (n2 * n3 * x + a * a - b * b);
    var c2 = 2.0 * (kf + a) * (kf + b) * n3;
    var den = 2.0 * (kf + 1.0) * (kf + a + b + 1.0) * n2;
    var p2 = 0.0;
    if den != 0.0 {
      p2 = (coef * p1 - c2 * p0) / den;
    }
    p0 = p1;
    p1 = p2;
    k = k + 1;
  }
  return p1;
}

/// Gegenbauer (ultraspherical) polynomial C_n^a(x). NaN for n < 0.
/// Complexity: O(n).
pub fn gegenbauer_c(n: Int, a: Float64, x: Float64) -> Float64 {
  if n < 0 { return 0.0 / 0.0; }
  if n == 0 { return 1.0; }
  if n == 1 { return 2.0 * a * x; }
  var c0 = 1.0;
  var c1 = 2.0 * a * x;
  var k = 1;
  while k < n {
    var c2 = (2.0 * ((k as Float64) + a) * x * c1 - ((k as Float64) + 2.0 * a - 1.0) * c0) / ((k as Float64) + 1.0);
    c0 = c1;
    c1 = c2;
    k = k + 1;
  }
  return c1;
}

/// Real spherical harmonic Y_l^m(theta, phi) using the quantum convention
/// Y_l^m = sqrt((2l+1)/(4 pi) (l-|m|)!/(l+|m|)!) P_l^|m|(cos theta) cos(m phi)
/// (m >= 0; m < 0 uses sin(|m| phi)). NaN for invalid l, m or theta outside
/// [0, pi]. Complexity: O(l).
pub fn spherical_harmonic(l: Int, m: Int, theta: Float64, phi: Float64) -> Float64 {
  if l < 0 { return 0.0 / 0.0; }
  var am = m;
  if am < 0 { am = -am; }
  if am > l { return 0.0 / 0.0; }
  if theta < 0.0 || theta > _PI { return 0.0 / 0.0; }
  var x = math.cos(theta);
  var plm = _assoc_legendre(l, am, x);
  var num = 1.0;
  var den = 1.0;
  var i = 1;
  while i <= am {
    num = num * ((l - i + 1) as Float64);
    den = den * ((l + i) as Float64);
    i = i + 1;
  }
  var norm = math.sqrt(((2.0 * (l as Float64) + 1.0) / (4.0 * _PI)) * num / den);
  var angle = (am as Float64) * phi;
  var trig = 1.0;
  if m >= 0 { trig = math.cos(angle); } else { trig = math.sin(angle); }
  return norm * plm * trig;
}

// Associated Legendre polynomial P_l^m(x) for |x| <= 1 via the standard
// recurrence (P_m^m, P_{m+1}^m, then upward in l).
fn _assoc_legendre(l: Int, m: Int, x: Float64) -> Float64 {
  if x >= 1.0 || x <= -1.0 {
    if m == 0 { return legendre_p(l, x); }
    return 0.0;
  }
  var pmm = 1.0;
  var s = math.sqrt(1.0 - x * x);
  var k = 1;
  while k <= m {
    pmm = -pmm * (2.0 * (k as Float64) - 1.0) * s;
    k = k + 1;
  }
  if l == m { return pmm; }
  var pmm1 = x * (2.0 * (m as Float64) + 1.0) * pmm;
  if l == m + 1 { return pmm1; }
  var p0 = pmm;
  var p1 = pmm1;
  var j = m + 1;
  while j < l {
    var p2 = ((2.0 * (j as Float64) + 1.0) * x * p1 - ((j as Float64) + (m as Float64)) * p0) / ((j as Float64) + 1.0 - (m as Float64));
    p0 = p1;
    p1 = p2;
    j = j + 1;
  }
  return p1;
}

// ---------------------------------------------------------------------------
// Airy functions
// ---------------------------------------------------------------------------

// Series coefficients of Ai: a_0 = Ai(0), a_1 = Ai'(0), a_2 = 0,
// a_{n+3} = a_n / ((n+1)(n+2)(n+3)).
fn _airy_series(x: Float64, b0: Float64, b1: Float64) -> Float64 {
  var sum = b0 + b1 * x;
  var a0 = b0;
  var a1 = b1;
  var a2 = 0.0;
  var n = 3;
  while n <= 60 {
    var an = a0 / (((n - 2) as Float64) * ((n - 1) as Float64) * (n as Float64));
    sum = sum + an * math.pow(x, n as Float64);
    a0 = a1;
    a1 = a2;
    a2 = an;
    n = n + 1;
  }
  return sum;
}

// Ai'(x) by termwise differentiation of the Ai series.
fn _airy_series_d(x: Float64, b0: Float64, b1: Float64) -> Float64 {
  var sum = b1;
  var a0 = b0;
  var a1 = b1;
  var a2 = 0.0;
  var n = 3;
  while n <= 60 {
    var an = a0 / (((n - 2) as Float64) * ((n - 1) as Float64) * (n as Float64));
    sum = sum + (n as Float64) * an * math.pow(x, (n - 1) as Float64);
    a0 = a1;
    a1 = a2;
    a2 = an;
    n = n + 1;
  }
  return sum;
}

/// Airy function of the first kind Ai(x). Series for |x| <= 6; for larger |x|
/// the asymptotic forms are used. Complexity: O(60).
pub fn airy_ai(x: Float64) -> Float64 {
  if x != x { return x; }
  var ax = math.abs_float(x);
  if ax <= 6.0 {
    return _airy_series(x, 0.3550280538878172, -0.2588194037928068);
  }
  if x > 6.0 {
    var xi = 2.0 / 3.0 * math.pow(x, 1.5);
    var p = 1.0 - 5.0 / (48.0 * xi) + 385.0 / (4608.0 * xi * xi);
    return p * math.exp(-xi) / (2.0 * math.sqrt(_PI) * math.pow(x, 0.25));
  }
  var ax4 = math.pow(-x, 0.25);
  var xi = 2.0 / 3.0 * math.pow(-x, 1.5);
  return (math.sin(xi + _PI / 4.0)) / (math.sqrt(_PI) * ax4);
}

/// Airy function of the second kind Bi(x). Series for |x| <= 6; asymptotic
/// for larger |x|. Complexity: O(60).
pub fn airy_bi(x: Float64) -> Float64 {
  if x != x { return x; }
  var ax = math.abs_float(x);
  if ax <= 6.0 {
    return _airy_series(x, 0.6149266274460007, 0.4482883573538263);
  }
  if x > 6.0 {
    var xi = 2.0 / 3.0 * math.pow(x, 1.5);
    var p = 1.0 + 5.0 / (48.0 * xi) + 385.0 / (4608.0 * xi * xi);
    return p * math.exp(xi) / (math.sqrt(_PI) * math.pow(x, 0.25));
  }
  var ax4 = math.pow(-x, 0.25);
  var xi = 2.0 / 3.0 * math.pow(-x, 1.5);
  return (math.cos(xi + _PI / 4.0)) / (math.sqrt(_PI) * ax4);
}

/// Derivative of the Airy function of the first kind Ai'(x). Series for
/// |x| <= 6; for larger |x| a central-difference of airy_ai is used.
/// Complexity: O(60).
pub fn airy_aip(x: Float64) -> Float64 {
  if x != x { return x; }
  if math.abs_float(x) <= 6.0 {
    return _airy_series_d(x, 0.3550280538878172, -0.2588194037928068);
  }
  var h = 1.0e-6 * math.abs_float(x);
  return (airy_ai(x + h) - airy_ai(x - h)) / (2.0 * h);
}

/// Derivative of the Airy function of the second kind Bi'(x). Series for
/// |x| <= 6; for larger |x| a central-difference of airy_bi is used.
/// Complexity: O(60).
pub fn airy_bip(x: Float64) -> Float64 {
  if x != x { return x; }
  if math.abs_float(x) <= 6.0 {
    return _airy_series_d(x, 0.6149266274460007, 0.4482883573538263);
  }
  var h = 1.0e-6 * math.abs_float(x);
  return (airy_bi(x + h) - airy_bi(x - h)) / (2.0 * h);
}

// ---------------------------------------------------------------------------
// Fresnel integrals
// ---------------------------------------------------------------------------

/// Sine integral S(x) = integral_0^x sin(pi t^2/2) dt. Series to 60 terms
/// (accurate for |x| <= 8); NaN for NaN. Complexity: O(60).
pub fn fresnel_s(x: Float64) -> Float64 {
  if x != x { return x; }
  var neg = x < 0.0;
  var ax = math.abs_float(x);
  var sum = 0.0;
  var n = 0;
  while n <= 60 {
    var p = math.pow(_PI, (2 * n + 1) as Float64);
    var q = math.pow(ax, (4 * n + 3) as Float64);
    var fact = 1.0;
    var i = 1;
    while i <= 2 * n + 1 {
      fact = fact * (i as Float64);
      i = i + 1;
    }
    var term = p * q / (math.pow(2.0, (2 * n + 1) as Float64) * fact * ((4 * n + 3) as Float64));
    if n % 2 == 1 { sum = sum - term; } else { sum = sum + term; }
    if term < 1.0e-16 * math.abs_float(sum) && n > 5 { n = 61; }
    n = n + 1;
  }
  if neg { return -sum; }
  return sum;
}

/// Cosine integral C(x) = integral_0^x cos(pi t^2/2) dt. Series to 60 terms.
/// Complexity: O(60).
pub fn fresnel_c(x: Float64) -> Float64 {
  if x != x { return x; }
  var sum = 0.0;
  var n = 0;
  while n <= 60 {
    var p = math.pow(_PI, (2 * n) as Float64);
    var q = math.pow(x, (4 * n + 1) as Float64);
    var fact = 1.0;
    var i = 1;
    while i <= 2 * n {
      fact = fact * (i as Float64);
      i = i + 1;
    }
    var term = p * q / (math.pow(2.0, (2 * n) as Float64) * fact * ((4 * n + 1) as Float64));
    if n % 2 == 1 { sum = sum - term; } else { sum = sum + term; }
    if term < 1.0e-16 * math.abs_float(sum) && n > 5 { n = 61; }
    n = n + 1;
  }
  return sum;
}

// ---------------------------------------------------------------------------
// Elliptic integrals
// ---------------------------------------------------------------------------

/// Complete elliptic integral of the first kind K(k) via the arithmetic-
/// geometric mean: K(k) = pi / (2 AGM(1, sqrt(1-k^2))). NaN for |k| > 1.
/// K(0) = pi/2 exactly. Complexity: O(AGM iterations).
pub fn elliptic_k(k: Float64) -> Float64 {
  if k != k { return k; }
  if math.abs_float(k) > 1.0 { return 0.0 / 0.0; }
  var k2 = k * k;
  if k2 == 0.0 { return _PI / 2.0; }
  if k2 == 1.0 { return 1.0 / 0.0; }
  var a = 1.0;
  var b = math.sqrt(1.0 - k2);
  var i = 0;
  while i < 60 {
    var c = 0.5 * (a + b);
    var d = math.sqrt(a * b);
    a = c;
    b = d;
    if math.abs_float(a - b) < 1.0e-15 { i = 60; }
    i = i + 1;
  }
  return _PI / (2.0 * a);
}

/// Complete elliptic integral of the second kind E(k) via the Legendre series
/// E(k) = (pi/2) [1 - sum ((2n-1)!!/(2n)!!)^2 k^(2n)/(2n-1)] for k^2 < 0.9;
/// for k^2 >= 0.9 the defining integral is integrated by Simpson's rule.
/// NaN for |k| > 1. Complexity: O(n^2) series / O(panels) quadrature.
pub fn elliptic_e(k: Float64) -> Float64 {
  if k != k { return k; }
  if math.abs_float(k) > 1.0 { return 0.0 / 0.0; }
  var k2 = k * k;
  if k2 == 0.0 { return _PI / 2.0; }
  if k2 == 1.0 { return 1.0; }
  if k2 < 0.9 {
    var sum = 1.0;
    var n = 1;
    while n <= 60 {
      var kpow = math.pow(k, 2.0 * (n as Float64));
      var num = 1.0;
      var den = 1.0;
      var j = 1;
      while j <= n {
        num = num * (2.0 * (j as Float64) - 1.0);
        den = den * (2.0 * (j as Float64));
        j = j + 1;
      }
      var ratio = num / den;
      var tn = ratio * ratio * kpow / (2.0 * (n as Float64) - 1.0);
      sum = sum - tn;
      n = n + 1;
    }
    return _PI / 2.0 * sum;
  }
  var m = 500;
  var h = _PI / 2.0 / (m as Float64);
  var sum = 0.0;
  var i = 0;
  while i <= m {
    var th = h * (i as Float64);
    var sn = math.sin(th);
    var f = math.sqrt(1.0 - k2 * sn * sn);
    var w = 1.0;
    if i == 0 || i == m { w = 1.0; }
    elif i % 2 == 1 { w = 4.0; }
    else { w = 2.0; }
    sum = sum + w * f;
    i = i + 1;
  }
  return h / 3.0 * sum;
}

/// Complete elliptic integral of the third kind Pi(n, k) = integral_0^(pi/2)
/// dtheta / ((1 - n sin^2 theta) sqrt(1 - k^2 sin^2 theta)) by Simpson
/// quadrature (500 panels). NaN for n > 1 or |k| > 1 (documented domain).
pub fn elliptic_pi(n: Float64, k: Float64) -> Float64 {
  if math.abs_float(k) > 1.0 || n > 1.0 { return 0.0 / 0.0; }
  if n == 0.0 { return elliptic_k(k); }
  var m = 500;
  var h = _PI / 2.0 / (m as Float64);
  var k2 = k * k;
  var sum = 0.0;
  var i = 0;
  while i <= m {
    var th = h * (i as Float64);
    var sn = math.sin(th);
    var sn2 = sn * sn;
    var denom = math.sqrt(1.0 - k2 * sn2);
    var f = 1.0 / ((1.0 - n * sn2) * denom);
    var w = 1.0;
    if i == 0 || i == m { w = 1.0; }
    elif i % 2 == 1 { w = 4.0; }
    else { w = 2.0; }
    sum = sum + w * f;
    i = i + 1;
  }
  return h / 3.0 * sum;
}

/// Incomplete elliptic integral of the first kind F(phi, k) =
/// integral_0^phi dtheta / sqrt(1 - k^2 sin^2 theta) by Simpson quadrature.
/// NaN for |k| > 1. Complexity: O(panels).
pub fn elliptic_f(phi: Float64, k: Float64) -> Float64 {
  if math.abs_float(k) > 1.0 { return 0.0 / 0.0; }
  if phi == 0.0 { return 0.0; }
  var m = 400;
  var k2 = k * k;
  var h = phi / (m as Float64);
  var sum = 0.0;
  var i = 0;
  while i <= m {
    var th = h * (i as Float64);
    var sn = math.sin(th);
    var denom = math.sqrt(1.0 - k2 * sn * sn);
    var f = 1.0 / denom;
    var w = 1.0;
    if i == 0 || i == m { w = 1.0; }
    elif i % 2 == 1 { w = 4.0; }
    else { w = 2.0; }
    sum = sum + w * f;
    i = i + 1;
  }
  return h / 3.0 * sum;
}

/// Incomplete elliptic integral of the second kind E(phi, k) =
/// integral_0^phi sqrt(1 - k^2 sin^2 theta) dtheta by Simpson quadrature.
/// NaN for |k| > 1. Complexity: O(panels).
pub fn elliptic_e_incomplete(phi: Float64, k: Float64) -> Float64 {
  if math.abs_float(k) > 1.0 { return 0.0 / 0.0; }
  if phi == 0.0 { return 0.0; }
  var m = 400;
  var k2 = k * k;
  var h = phi / (m as Float64);
  var sum = 0.0;
  var i = 0;
  while i <= m {
    var th = h * (i as Float64);
    var sn = math.sin(th);
    var f = math.sqrt(1.0 - k2 * sn * sn);
    var w = 1.0;
    if i == 0 || i == m { w = 1.0; }
    elif i % 2 == 1 { w = 4.0; }
    else { w = 2.0; }
    sum = sum + w * f;
    i = i + 1;
  }
  return h / 3.0 * sum;
}

/// Incomplete elliptic integral of the third kind Pi(n; phi, k) by Simpson
/// quadrature. NaN for n > 1 or |k| > 1. Complexity: O(panels).
pub fn elliptic_pi_incomplete(n: Float64, phi: Float64, k: Float64) -> Float64 {
  if math.abs_float(k) > 1.0 || n > 1.0 { return 0.0 / 0.0; }
  if phi == 0.0 { return 0.0; }
  var m = 400;
  var k2 = k * k;
  var h = phi / (m as Float64);
  var sum = 0.0;
  var i = 0;
  while i <= m {
    var th = h * (i as Float64);
    var sn = math.sin(th);
    var sn2 = sn * sn;
    var denom = math.sqrt(1.0 - k2 * sn2);
    var f = 1.0 / ((1.0 - n * sn2) * denom);
    var w = 1.0;
    if i == 0 || i == m { w = 1.0; }
    elif i % 2 == 1 { w = 4.0; }
    else { w = 2.0; }
    sum = sum + w * f;
    i = i + 1;
  }
  return h / 3.0 * sum;
}

// ---------------------------------------------------------------------------
// Jacobi theta functions
// ---------------------------------------------------------------------------

/// theta_1(x, q) = 2 sum_{n>=0} (-1)^n q^((n+1/2)^2) sin((2n+1)x).
/// Converges for 0 < q < 1 (real-domain); NaN otherwise. Complexity: O(terms).
pub fn theta_1(x: Float64, q: Float64) -> Float64 {
  if q <= 0.0 || q >= 1.0 { return 0.0 / 0.0; }
  var sum = 0.0;
  var n = 0;
  while n <= 100 {
    var e = ((n as Float64) + 0.5) * ((n as Float64) + 0.5);
    var qp = math.pow(q, e);
    var term = qp * math.sin((2.0 * (n as Float64) + 1.0) * x);
    if n % 2 == 1 { sum = sum - term; } else { sum = sum + term; }
    if math.abs_float(qp) < 1.0e-16 && n > 3 { n = 101; }
    n = n + 1;
  }
  return 2.0 * sum;
}

/// theta_2(x, q) = 2 sum_{n>=0} q^((n+1/2)^2) cos((2n+1)x). Converges for
/// 0 < q < 1 (real-domain); NaN otherwise. Complexity: O(terms).
pub fn theta_2(x: Float64, q: Float64) -> Float64 {
  if q <= 0.0 || q >= 1.0 { return 0.0 / 0.0; }
  var sum = 0.0;
  var n = 0;
  while n <= 100 {
    var e = ((n as Float64) + 0.5) * ((n as Float64) + 0.5);
    var qp = math.pow(q, e);
    sum = sum + qp * math.cos((2.0 * (n as Float64) + 1.0) * x);
    if math.abs_float(qp) < 1.0e-16 && n > 3 { n = 101; }
    n = n + 1;
  }
  return 2.0 * sum;
}

/// theta_3(x, q) = 1 + 2 sum_{n>=1} q^(n^2) cos(2nx). Complexity: O(terms).
pub fn theta_3(x: Float64, q: Float64) -> Float64 {
  if math.abs_float(q) >= 1.0 { return 0.0 / 0.0; }
  var sum = 1.0;
  var n = 1;
  while n <= 100 {
    var qp = math.pow(q, (n as Float64) * (n as Float64));
    sum = sum + 2.0 * qp * math.cos(2.0 * (n as Float64) * x);
    if math.abs_float(qp) < 1.0e-16 && n > 3 { n = 101; }
    n = n + 1;
  }
  return sum;
}

/// theta_4(x, q) = 1 + 2 sum_{n>=1} (-1)^n q^(n^2) cos(2nx). Complexity: O(terms).
pub fn theta_4(x: Float64, q: Float64) -> Float64 {
  if math.abs_float(q) >= 1.0 { return 0.0 / 0.0; }
  var sum = 1.0;
  var n = 1;
  while n <= 100 {
    var qp = math.pow(q, (n as Float64) * (n as Float64));
    var term = 2.0 * qp * math.cos(2.0 * (n as Float64) * x);
    if n % 2 == 1 { sum = sum - term; } else { sum = sum + term; }
    if math.abs_float(qp) < 1.0e-16 && n > 3 { n = 101; }
    n = n + 1;
  }
  return sum;
}

// ---------------------------------------------------------------------------
// Integral functions
// ---------------------------------------------------------------------------

/// Exponential integral Ei(x) = gamma + ln|x| + sum x^k/(k k!) (Cauchy
/// principal value for x < 0). At most 80 terms; Ei(0) = -inf.
/// Complexity: O(n^2).
pub fn exponential_integral(x: Float64) -> Float64 {
  if x != x { return x; }
  if x == 0.0 { return -1.0 / 0.0; }
  var sum = _EULER_GAMMA + math.ln(math.abs_float(x));
  var k = 1;
  while k <= 80 {
    var p = math.pow(x, k as Float64);
    var fact = 1.0;
    var j = 1;
    while j <= k {
      fact = fact * (j as Float64);
      j = j + 1;
    }
    sum = sum + p / ((k as Float64) * fact);
    k = k + 1;
  }
  return sum;
}

/// Logarithmic integral li(x) = Ei(ln x) for x > 0, x != 1. li(1) = -inf,
/// li(0) = 0, li(x) for x < 0 is NaN (branch cut). Complexity: O(Ei terms).
pub fn li(x: Float64) -> Float64 {
  if x != x { return x; }
  if x < 0.0 { return 0.0 / 0.0; }
  if x == 0.0 { return 0.0; }
  if x == 1.0 { return -1.0 / 0.0; }
  return exponential_integral(math.ln(x));
}

/// Offset logarithmic integral Li(x) = li(x) - li(2). Same domain as li.
/// Complexity: O(Ei terms).
pub fn li_offset(x: Float64) -> Float64 {
  if x != x { return x; }
  if x < 0.0 { return 0.0 / 0.0; }
  if x == 0.0 { return -li(2.0); }
  if x == 1.0 { return -1.0 / 0.0; }
  var l2 = exponential_integral(0.6931471805599453);
  return exponential_integral(math.ln(x)) - l2;
}

/// Sine integral Si(x) = integral_0^x sin(t)/t dt via its alternating power
/// series sum (-1)^n x^(2n+1)/((2n+1)(2n+1)!). Complexity: O(n^2).
pub fn sin_integral(x: Float64) -> Float64 {
  if x != x { return x; }
  var neg = x < 0.0;
  var ax = math.abs_float(x);
  var sum = 0.0;
  var n = 0;
  while n <= 40 {
    var p = math.pow(ax, (2 * n + 1) as Float64);
    var fact = 1.0;
    var j = 1;
    while j <= 2 * n + 1 {
      fact = fact * (j as Float64);
      j = j + 1;
    }
    var t = p / ((2.0 * (n as Float64) + 1.0) * fact);
    if n % 2 == 1 { sum = sum - t; } else { sum = sum + t; }
    n = n + 1;
  }
  if neg { return -sum; }
  return sum;
}

/// Cosine integral Ci(x) = gamma + ln x + sum (-1)^n x^(2n)/((2n)(2n)!) for
/// x > 0. NaN for x < 0 (branch cut); Ci(0) = -inf. Complexity: O(n^2).
pub fn cos_integral(x: Float64) -> Float64 {
  if x != x { return x; }
  if x < 0.0 { return 0.0 / 0.0; }
  if x == 0.0 { return -1.0 / 0.0; }
  var sum = _EULER_GAMMA + math.ln(x);
  var n = 1;
  while n <= 40 {
    var p = math.pow(x, (2 * n) as Float64);
    var fact = 1.0;
    var j = 1;
    while j <= 2 * n {
      fact = fact * (j as Float64);
      j = j + 1;
    }
    var t = p / ((2.0 * (n as Float64)) * fact);
    if n % 2 == 1 { sum = sum - t; } else { sum = sum + t; }
    n = n + 1;
  }
  return sum;
}

// ---------------------------------------------------------------------------
// Hypergeometric functions
// ---------------------------------------------------------------------------

/// Gauss hypergeometric function 2F1(a, b; c; x) by series summation (rising
/// factorials), convergent for |x| < 1. NaN for |x| > 1 (divergent) or
/// c <= 0 (singular). Complexity: O(terms).
pub fn hypergeometric_2f1(a: Float64, b: Float64, c: Float64, x: Float64) -> Float64 {
  if c <= 0.0 { return 0.0 / 0.0; }
  if math.abs_float(x) > 1.0 { return 0.0 / 0.0; }
  var sum = 1.0;
  var term = 1.0;
  var n = 0;
  while n <= 200 {
    term = term * (a + (n as Float64)) * (b + (n as Float64)) * x / ((c + (n as Float64)) * ((n as Float64) + 1.0));
    sum = sum + term;
    if math.abs_float(term) < 1.0e-15 * math.abs_float(sum) && n > 3 { n = 201; }
    n = n + 1;
  }
  return sum;
}

/// Confluent hypergeometric function 1F1(a; b; x) by series summation
/// (converges for all x). NaN for b <= 0. Complexity: O(terms).
pub fn hypergeometric_1f1(a: Float64, b: Float64, x: Float64) -> Float64 {
  if b <= 0.0 { return 0.0 / 0.0; }
  var sum = 1.0;
  var term = 1.0;
  var n = 0;
  while n <= 200 {
    term = term * (a + (n as Float64)) * x / ((b + (n as Float64)) * ((n as Float64) + 1.0));
    sum = sum + term;
    if math.abs_float(term) < 1.0e-15 * math.abs_float(sum) && n > 3 { n = 201; }
    n = n + 1;
  }
  return sum;
}
