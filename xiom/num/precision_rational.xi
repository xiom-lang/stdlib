// XIOM - Num: Precision Rational
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.num.precision_rational

// Depends on: xiom.math

// ============================================================================
// Arbitrary-precision rational numbers (BigRat): construction, arithmetic,
// reduction, and comparison. Representation: num/den with den > 0 and
// gcd(|num|, den) == 1, where num and den are arbitrary-precision BigInts.
// INVARIANT: every BigRat produced by this module is reduced with a positive
// denominator (all construction and arithmetic routes through bigrat_new).
// ============================================================================

use xiom.bigint;
use xiom.string;
use xiom.core.to_float;

/// Arbitrary-precision rational number: num/den, den > 0, always reduced.
pub type BigRat = { num: BigInt; den: BigInt; }

/// Constructs a reduced BigRat from num/den, normalizing the sign to the
/// denominator. None when den is zero. Zero maps to 0/1.
/// Complexity: O(gcd) bigint operations.
pub fn bigrat_new(num: BigInt, den: BigInt) -> Option[BigRat] {
  if xiom.bigint.bigint_is_zero(&den) { return None; }
  var n = num;
  var d = den;
  if xiom.bigint.bigint_is_negative(&d) {
    n = xiom.bigint.bigint_neg(&n);
    d = xiom.bigint.bigint_neg(&d);
  }
  if xiom.bigint.bigint_is_zero(&n) {
    return Some(BigRat{ num: xiom.bigint.bigint_zero(); den: xiom.bigint.bigint_one(); });
  }
  var g = xiom.bigint.bigint_gcd(&n, &d);
  if !xiom.bigint.bigint_is_one(&g) {
    n = xiom.bigint.bigint_div(&n, &g);
    d = xiom.bigint.bigint_div(&d, &g);
  }
  Some(BigRat{ num: n; den: d; })
}

/// Constructs the BigRat v/1. Complexity: O(1).
pub fn bigrat_from_int(v: Int) -> BigRat {
  BigRat{ num: xiom.bigint.bigint_from_int(v); den: xiom.bigint.bigint_one(); }
}

/// Parses "num/den" (optional signs) or a decimal string ("3.14", "-0.5").
/// None on invalid input, empty parts, or a zero denominator.
/// Complexity: O(n^2) via the bigint accumulation.
pub fn bigrat_from_str(s: Str) -> Option[BigRat] {
  if s.len() == 0 { return None; }
  var neg = false;
  var t = s;
  var first = xiom.string.str_slice(s, 0, 1);
  if first == "-" {
    neg = true;
    t = xiom.string.str_slice(s, 1, s.len());
  } elif first == "+" {
    t = xiom.string.str_slice(s, 1, s.len());
  }
  if t.len() == 0 { return None; }
  var slash = -1;
  var i = 0;
  while i < t.len() {
    if xiom.string.byte_at(t, i) == 47 { slash = i; break; }
    i = i + 1;
  }
  if slash >= 0 {
    var num_s = xiom.string.str_slice(t, 0, slash);
    var den_s = xiom.string.str_slice(t, slash + 1, t.len());
    if num_s.len() == 0 || den_s.len() == 0 { return None; }
    var num_r = xiom.bigint.bigint_from_str(num_s);
    var den_r = xiom.bigint.bigint_from_str(den_s);
    match num_r {
      Err(_) => { return None; }
      Ok(nv) => {
        match den_r {
          Err(_) => { return None; }
          Ok(dv) => {
            if xiom.bigint.bigint_is_zero(&dv) { return None; }
            var r = bigrat_new(nv, dv);
            match r {
              None => { return None; }
              Some(v) => {
                if neg { v.num = xiom.bigint.bigint_neg(&v.num); }
                return Some(v);
              }
            }
          }
        }
      }
    }
  }
  // Decimal form: split at the single '.'.
  var dot = -1;
  var j = 0;
  while j < t.len() {
    if xiom.string.byte_at(t, j) == 46 { dot = j; break; }
    j = j + 1;
  }
  var int_s = t;
  var frac_s = "";
  if dot >= 0 {
    int_s = xiom.string.str_slice(t, 0, dot);
    frac_s = xiom.string.str_slice(t, dot + 1, t.len());
  }
  var int_r = xiom.bigint.bigint_from_str(int_s);
  match int_r {
    Err(_) => { return None; }
    Ok(iv) => {
      if frac_s.len() == 0 {
        if neg && !xiom.bigint.bigint_is_zero(&iv) {
          return Some(BigRat{ num: xiom.bigint.bigint_neg(&iv); den: xiom.bigint.bigint_one(); });
        }
        return Some(BigRat{ num: iv; den: xiom.bigint.bigint_one(); });
      }
      var frac_r = xiom.bigint.bigint_from_str(frac_s);
      match frac_r {
        Err(_) => { return None; }
        Ok(fv) => {
          var ten = xiom.bigint.bigint_from_int(10);
          var den = xiom.bigint.bigint_pow(&ten, frac_s.len());
          var num = xiom.bigint.bigint_add(&xiom.bigint.bigint_mul(&iv, &den), &fv);
          var r = bigrat_new(num, den);
          match r {
            None => { return None; }
            Some(v) => {
              if neg { v.num = xiom.bigint.bigint_neg(&v.num); }
              return Some(v);
            }
          }
        }
      }
    }
  }
}

/// String representation: "num" when the denominator is 1, else "num/den".
/// Complexity: O(n).
pub fn bigrat_to_str(r: BigRat) -> Str {
  if xiom.bigint.bigint_is_one(&r.den) {
    return xiom.bigint.bigint_to_str(&r.num);
  }
  xiom.bigint.bigint_to_str(&r.num) + "/" + xiom.bigint.bigint_to_str(&r.den)
}

/// The numerator (a copy). Complexity: O(n).
pub fn bigrat_numerator(r: BigRat) -> BigInt {
  return r.num;
}

/// The denominator (always positive; a copy). Complexity: O(n).
pub fn bigrat_denominator(r: BigRat) -> BigInt {
  return r.den;
}

/// Sum a + b: (a.num*b.den + b.num*a.den) / (a.den*b.den), reduced.
/// Complexity: O(n^2) bigint operations.
pub fn bigrat_add(a: BigRat, b: BigRat) -> BigRat {
  var t1 = xiom.bigint.bigint_mul(&a.num, &b.den);
  var t2 = xiom.bigint.bigint_mul(&b.num, &a.den);
  var num = xiom.bigint.bigint_add(&t1, &t2);
  var den = xiom.bigint.bigint_mul(&a.den, &b.den);
  bigrat_reduce(BigRat{ num: num; den: den; })
}

/// Difference a - b. Complexity: O(n^2).
pub fn bigrat_sub(a: BigRat, b: BigRat) -> BigRat {
  var t1 = xiom.bigint.bigint_mul(&a.num, &b.den);
  var t2 = xiom.bigint.bigint_mul(&b.num, &a.den);
  var num = xiom.bigint.bigint_sub(&t1, &t2);
  var den = xiom.bigint.bigint_mul(&a.den, &b.den);
  bigrat_reduce(BigRat{ num: num; den: den; })
}

/// Product a * b. Complexity: O(n^2).
pub fn bigrat_mul(a: BigRat, b: BigRat) -> BigRat {
  var num = xiom.bigint.bigint_mul(&a.num, &b.num);
  var den = xiom.bigint.bigint_mul(&a.den, &b.den);
  bigrat_reduce(BigRat{ num: num; den: den; })
}

/// Quotient a / b. None when b is zero. The denominator sign is normalized
/// by the reduction. Complexity: O(n^2).
pub fn bigrat_div(a: BigRat, b: BigRat) -> Option[BigRat] {
  if xiom.bigint.bigint_is_zero(&b.num) { return None; }
  var num = xiom.bigint.bigint_mul(&a.num, &b.den);
  var den = xiom.bigint.bigint_mul(&a.den, &b.num);
  Some(bigrat_reduce(BigRat{ num: num; den: den; }))
}

/// Negation. Complexity: O(n).
pub fn bigrat_neg(a: BigRat) -> BigRat {
  BigRat{ num: xiom.bigint.bigint_neg(&a.num); den: a.den; }
}

/// Absolute value. Complexity: O(n).
pub fn bigrat_abs(a: BigRat) -> BigRat {
  BigRat{ num: xiom.bigint.bigint_abs(&a.num); den: a.den; }
}

/// Reciprocal 1/a. None when a is zero. Complexity: O(n^2) reduction.
pub fn bigrat_recip(a: BigRat) -> Option[BigRat] {
  if xiom.bigint.bigint_is_zero(&a.num) { return None; }
  var r = BigRat{ num: a.den; den: a.num; };
  Some(bigrat_reduce(r))
}

/// Reduces r to lowest terms with a positive denominator. Identity when r
/// already satisfies the invariant. Complexity: O(gcd).
pub fn bigrat_reduce(r: BigRat) -> BigRat {
  var o = bigrat_new(r.num, r.den);
  match o {
    None => { return r; }
    Some(v) => { return v; }
  }
}

/// Whether r is in lowest terms with a positive denominator.
/// Complexity: O(gcd).
pub fn bigrat_is_reduced(r: BigRat) -> Bool {
  if xiom.bigint.bigint_is_negative(&r.den) { return false; }
  var g = xiom.bigint.bigint_gcd(&r.num, &r.den);
  xiom.bigint.bigint_is_one(&g)
}

/// Whether the denominator divides the numerator (i.e. r is an integer;
/// for a reduced fraction this is den == 1). Complexity: O(1).
pub fn bigrat_is_integer(r: BigRat) -> Bool {
  xiom.bigint.bigint_is_one(&r.den)
}

/// Whether r equals zero. Complexity: O(1).
pub fn bigrat_is_zero(r: BigRat) -> Bool {
  xiom.bigint.bigint_is_zero(&r.num)
}

/// Three-way comparison via cross-multiplication: -1, 0, or 1.
/// Valid because denominators are positive. Complexity: O(n^2).
pub fn bigrat_compare(a: BigRat, b: BigRat) -> Int {
  var lhs = xiom.bigint.bigint_mul(&a.num, &b.den);
  var rhs = xiom.bigint.bigint_mul(&b.num, &a.den);
  xiom.bigint.bigint_compare(&lhs, &rhs)
}

/// Whether a equals b. Complexity: O(n^2).
pub fn bigrat_eq(a: BigRat, b: BigRat) -> Bool {
  bigrat_compare(a, b) == 0
}

/// Converts to Float64 (bigint magnitude accumulation, then division).
/// The result may be inf for values beyond the Float64 range (documented).
/// Complexity: O(n).
pub fn bigrat_to_float(r: BigRat) -> Float64 {
  if xiom.bigint.bigint_is_zero(&r.num) { return 0.0; }
  var num_f = _bigint_to_float(&r.num);
  var den_f = _bigint_to_float(&r.den);
  if den_f == 0.0 { return 0.0; }
  num_f / den_f
}

/// Magnitude of a BigInt as Float64 (Horn: result = result*1e9 + digit).
fn _bigint_to_float(b: &BigInt) -> Float64 {
  var result = 0.0;
  var base = 1000000000.0;
  var i = b.digits.len() - 1;
  while i >= 0 {
    result = result * base + to_float(b.digits[i]);
    i = i - 1;
  }
  if b.negative { result = -result; }
  result
}

/// The integer value of r; None when r is not integral.
/// Complexity: O(1) (reduced form: integral iff den == 1).
pub fn bigrat_to_integer(r: BigRat) -> Option[BigInt] {
  if !bigrat_is_integer(r) { return None; }
  Some(r.num)
}
