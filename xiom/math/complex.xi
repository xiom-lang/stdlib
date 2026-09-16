// XIOM -- Complex Number Library (a + bi arithmetic, transcendentials)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.complex

use xiom.math;

// ============================================================================
// Type -- Complex number with real and imaginary parts
// ============================================================================

// Complex number in Cartesian form: re + im * i.
pub type Complex = { re: Float64; im: Float64; }

// ============================================================================
// Construction and basic arithmetic
// ============================================================================

// Create a complex number from real and imaginary parts. O(1).
pub fn complex_new(re: Float64, im: Float64) -> Complex {
  return Complex{ re: re; im: im; };
}

// Create a complex number from polar form (magnitude r, phase theta). O(1).
// z = r * (cos(theta) + i * sin(theta))
pub fn complex_from_polar(r: Float64, theta: Float64) -> Complex {
  return Complex{ re: r * math.cos(theta); im: r * math.sin(theta); };
}

// Add two complex numbers: (a+bi) + (c+di) = (a+c) + (b+d)i. O(1).
pub fn complex_add(a: Complex, b: Complex) -> Complex {
  return Complex{ re: a.re + b.re; im: a.im + b.im; };
}

// Subtract b from a: (a+bi) - (c+di) = (a-c) + (b-d)i. O(1).
pub fn complex_sub(a: Complex, b: Complex) -> Complex {
  return Complex{ re: a.re - b.re; im: a.im - b.im; };
}

// Multiply two complex numbers: (a+bi)(c+di) = (ac-bd) + (ad+bc)i. O(1).
pub fn complex_mul(a: Complex, b: Complex) -> Complex {
  return Complex{
    re: a.re * b.re - a.im * b.im;
    im: a.re * b.im + a.im * b.re;
  };
}

// Divide a by b: (a+bi)/(c+di) = (ac+bd)/(c2+d2) + i*(bc-ad)/(c2+d2). O(1).
pub fn complex_div(a: Complex, b: Complex) -> Complex {
  var denom = b.re * b.re + b.im * b.im;
  return Complex{
    re: (a.re * b.re + a.im * b.im) / denom;
    im: (a.im * b.re - a.re * b.im) / denom;
  };
}

// Multiply a complex number by a real scalar. O(1).
pub fn complex_scale(z: Complex, s: Float64) -> Complex {
  return Complex{ re: z.re * s; im: z.im * s; };
}

// ============================================================================
// Complex conjugate, magnitude, phase
// ============================================================================

// Conjugate: conj(a+bi) = a - bi. O(1).
pub fn complex_conj(z: Complex) -> Complex {
  return Complex{ re: z.re; im: -z.im; };
}

// Absolute value (magnitude, modulus): |z| = sqrt(re2 + im2). O(1).
pub fn complex_abs(z: Complex) -> Float64 {
  return math.sqrt(z.re * z.re + z.im * z.im);
}

// Argument (phase, angle): atan2(im, re) in radians (-pi, pi]. O(1).
pub fn complex_arg(z: Complex) -> Float64 {
  return math.atan2(z.im, z.re);
}

// ============================================================================
// Equality and zero checks
// ============================================================================

// Check if the complex number is approximately equal to another within epsilon.
// Uses absolute tolerance comparison. O(1).
pub fn complex_equals(a: Complex, b: Complex, eps: Float64) -> Bool {
  return math.abs_float(a.re - b.re) < eps
      && math.abs_float(a.im - b.im) < eps;
}

// Check if the complex number is approximately zero within epsilon. O(1).
pub fn complex_is_zero(z: Complex, eps: Float64) -> Bool {
  return math.abs_float(z.re) < eps && math.abs_float(z.im) < eps;
}

// ============================================================================
// Private helpers -- hyperbolic functions
// ============================================================================

// Hyperbolic cosine: cosh(x) = (e^x + e^-x) / 2. O(1).
fn _cosh(x: Float64) -> Float64 {
  return (math.exp(x) + math.exp(-x)) / 2.0;
}

// Hyperbolic sine: sinh(x) = (e^x - e^-x) / 2. O(1).
fn _sinh(x: Float64) -> Float64 {
  return (math.exp(x) - math.exp(-x)) / 2.0;
}

// ============================================================================
// Exponential and logarithm
// ============================================================================

// Complex exponential: exp(a+bi) = e^a * (cos(b) + i*sin(b)). O(1).
// Euler's formula: e^(i*b) = cos(b) + i*sin(b).
pub fn complex_exp(z: Complex) -> Complex {
  var e_a = math.exp(z.re);
  return Complex{ re: e_a * math.cos(z.im); im: e_a * math.sin(z.im); };
}

// Complex natural logarithm (principal branch).
// ln(z) = ln(|z|) + i * arg(z), where arg(z) in (-pi, pi]. O(1).
pub fn complex_log(z: Complex) -> Complex {
  return Complex{ re: math.ln(complex_abs(z)); im: complex_arg(z); };
}

// ============================================================================
// Power and square root
// ============================================================================

// Complex power: z^w = exp(w * ln(z)).
// Uses the principal branch of the logarithm. O(1).
pub fn complex_pow(z: Complex, w: Complex) -> Complex {
  return complex_exp(complex_mul(w, complex_log(z)));
}

// Complex square root (principal branch).
// Formula: sqrt(z) = sqrt(r) * (cos(theta/2) + i*sin(theta/2)) where r=|z|, theta=arg(z).
// Also handles negative re branch properly. O(1).
pub fn complex_sqrt(z: Complex) -> Complex {
  // if z is real and non-negative, use real sqrt
  if z.im == 0.0 && z.re >= 0.0 {
    return Complex{ re: math.sqrt(z.re); im: 0.0; };
  }
  // general case: sqrt(|z|) * e^(i*theta/2)
  var r = complex_abs(z);
  var theta = complex_arg(z);
  var sqrt_r = math.sqrt(r);
  return Complex{ re: sqrt_r * math.cos(theta * 0.5); im: sqrt_r * math.sin(theta * 0.5); };
}

// ============================================================================
// Trigonometric functions
// ============================================================================

// Complex sine: sin(a+bi) = sin(a)*cosh(b) + i*cos(a)*sinh(b). O(1).
pub fn complex_sin(z: Complex) -> Complex {
  return Complex{
    re: math.sin(z.re) * _cosh(z.im);
    im: math.cos(z.re) * _sinh(z.im);
  };
}

// Complex cosine: cos(a+bi) = cos(a)*cosh(b) - i*sin(a)*sinh(b). O(1).
pub fn complex_cos(z: Complex) -> Complex {
  return Complex{
    re: math.cos(z.re) * _cosh(z.im);
    im: -math.sin(z.re) * _sinh(z.im);
  };
}

// Complex tangent: tan(z) = sin(z) / cos(z).
// Uses tan(a+bi) = (sin(2a) + i*sinh(2b)) / (cos(2a) + cosh(2b)). O(1).
pub fn complex_tan(z: Complex) -> Complex {
  var denom = math.cos(2.0 * z.re) + _cosh(2.0 * z.im);
  return Complex{
    re: math.sin(2.0 * z.re) / denom;
    im: _sinh(2.0 * z.im) / denom;
  };
}

// ============================================================================
// String conversion
// ============================================================================

// Convert a complex number to a human-readable string "a + bi".
// Uses built-in to_string and manual decimal string building. O(n) in digits.
pub fn complex_to_string(z: Complex) -> Str {
  var result = _float_to_str(z.re);
  if z.im >= 0.0 {
    result = result + " + ";
  } else {
    result = result + " - ";
  }
  result = result + _float_to_str(math.abs_float(z.im));
  result = result + "i";
  return result;
}

// Private: convert a float to a string with up to 6 fractional digits.
fn _float_to_str(f: Float64) -> Str {
  if f == 0.0 { return "0.0"; }
  var result = "";
  var neg = false;
  var val = f;
  if val < 0.0 {
    neg = true;
    val = -val;
  }
  // integer part via built-in to_string
  var ip = math.floor(val);
  var ip_int = ip as Int;
  result = to_string(ip_int);
  // fractional part: up to 6 digits
  var frac = val - ip;
  if frac > 0.0 {
    result = result + ".";
    var count = 0;
    while count < 6 {
      frac = frac * 10.0;
      var digit = math.floor(frac);
      var d = digit as Int;
      result = result + to_string(d);
      frac = frac - digit;
      count = count + 1;
    }
  } else {
    result = result + ".0";
  }
  if neg { return "-" + result; }
  return result;
}
