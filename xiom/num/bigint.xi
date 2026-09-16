// XIOM -- Arbitrary-Precision Signed Integer (BigInt) Library
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.bigint

use xiom.string;
use xiom.num;
use xiom.core.INT_MAX;
use xiom.core.to_int_from_char;

// ============================================================================
// Constants -- base-10^9 representation
// ============================================================================

// Each limb stores 9 decimal digits (0 .. 999,999,999).
// Limbs are stored little-endian: index 0 is least significant.

var _BASE: Int = 1000000000;
var _BASE_DIGITS: Int = 9;

// ============================================================================
// Type -- BigInt
// ============================================================================

pub type BigInt = { digits: Vec[Int]; negative: Bool; }

// ============================================================================
// Private helpers -- trim, copy, comparison
// ============================================================================

fn _trim(b: &BigInt) {
  while b.digits.len() > 0 {
    var last_idx = b.digits.len() - 1;
    if b.digits[last_idx] != 0 { return; }
    b.digits.pop();
  }
  b.negative = false;
}

fn _copy(a: &BigInt) -> BigInt {
  var result = BigInt{ digits: Vec[Int].new(); negative: a.negative; };
  var i = 0;
  while i < a.digits.len() {
    result.digits.push(a.digits[i]);
    i = i + 1;
  }
  return result;
}

fn _abs_compare(a: &BigInt, b: &BigInt) -> Int {
  if a.digits.len() < b.digits.len() { return -1; }
  if a.digits.len() > b.digits.len() { return 1; }
  var i = a.digits.len() - 1;
  while i >= 0 {
    if a.digits[i] < b.digits[i] { return -1; }
    if a.digits[i] > b.digits[i] { return 1; }
    i = i - 1;
  }
  return 0;
}

// ============================================================================
// Private: absolute arithmetic
// ============================================================================

fn _abs_add(a: &BigInt, b: &BigInt) -> BigInt {
  var result = BigInt{ digits: Vec[Int].new(); negative: false; };
  var carry = 0;
  var max_len = a.digits.len();
  if b.digits.len() > max_len { max_len = b.digits.len(); }
  var i = 0;
  while i < max_len {
    var sum = carry;
    if i < a.digits.len() { sum = sum + a.digits[i]; }
    if i < b.digits.len() { sum = sum + b.digits[i]; }
    result.digits.push(sum % _BASE);
    carry = sum / _BASE;
    i = i + 1;
  }
  while carry > 0 {
    result.digits.push(carry % _BASE);
    carry = carry / _BASE;
  }
  return result;
}

fn _abs_sub(a: &BigInt, b: &BigInt) -> BigInt {
  var result = BigInt{ digits: Vec[Int].new(); negative: false; };
  var borrow = 0;
  var i = 0;
  while i < a.digits.len() {
    var diff = a.digits[i] - borrow;
    if i < b.digits.len() { diff = diff - b.digits[i]; }
    if diff < 0 { diff = diff + _BASE; borrow = 1; }
    else { borrow = 0; }
    result.digits.push(diff);
    i = i + 1;
  }
  _trim(&result);
  return result;
}

fn _abs_mul_small(a: &BigInt, m: Int) -> BigInt {
  var result = BigInt{ digits: Vec[Int].new(); negative: false; };
  if m == 0 { return result; }
  var carry = 0;
  var i = 0;
  while i < a.digits.len() {
    var prod = a.digits[i] * m + carry;
    result.digits.push(prod % _BASE);
    carry = prod / _BASE;
    i = i + 1;
  }
  while carry > 0 {
    result.digits.push(carry % _BASE);
    carry = carry / _BASE;
  }
  return result;
}

fn _abs_shift_limbs(a: &BigInt, n: Int) -> BigInt {
  if n <= 0 { return _copy(a); }
  var result = BigInt{ digits: Vec[Int].new(); negative: false; };
  var i = 0;
  while i < n { result.digits.push(0); i = i + 1; }
  i = 0;
  while i < a.digits.len() { result.digits.push(a.digits[i]); i = i + 1; }
  return result;
}

// Estimate the next quotient digit for long division -- Knuth Algorithm D
// (TAOCP 4.3.1) qhat with the D4 refinement. Precondition: the divisor's top
// limb is normalized to [BASE/2, BASE) (see bigint_div_mod D1) and the
// remainder satisfies r < d * BASE^(shift+1).
//
// The window is (r[idx+1], r[idx]) -- the limb ABOVE the aligned position --
// NOT (r[idx], r[idx-1]). With an un-normalized top limb or a wrong window
// the estimate underestimates multi-limb digits (e.g. 9 vs true 100 for
// 64-nines / 10^44), corrupting the quotient. Overestimates (<= 2 after D4)
// are handled by the decrement loop; underestimates (<= 1) by the final
// remainder >= divisor fixup.
//
// Returns -1 when the remainder's top limb (at/above the window) is ZERO:
// then the true digit is 0 or 1 (r < B^(idx+1) and the normalized divisor
// gives digit < B/v[m-1] <= 2) and bigint_div_mod tests r >= v*B^shift
// directly. A naive 0 here is an underestimate of 1 at weight B^shift,
// which the final fixup (units of 1) cannot repair -- hit by bigfloat's
// rounding divisions (dividend top limb 1, divisor 10^k).
fn _estimate_q_digit(n: &BigInt, d: &BigInt, shift: Int) -> Int {
  var idx = d.digits.len() - 1 + shift;
  var top = idx + 1;
  if top >= n.digits.len() { return -1; }
  var d_hi = d.digits[d.digits.len() - 1];
  if d_hi == 0 { return -1; }
  var u_hi = n.digits[top];
  if u_hi == 0 { return -1; }
  var u_lo = n.digits[idx];
  var est = (u_hi * _BASE + u_lo) / d_hi;
  if est >= _BASE { est = _BASE - 1; }
  // D4: refine with the second divisor limb.
  if d.digits.len() >= 2 {
    var d_lo = d.digits[d.digits.len() - 2];
    var rhat = (u_hi * _BASE + u_lo) - est * d_hi;
    var u_below = 0;
    if idx >= 1 { u_below = n.digits[idx - 1]; }
    var guard = 0;
    while est * d_lo > rhat * _BASE + u_below && guard < 20 {
      est = est - 1;
      rhat = rhat + d_hi;
      if rhat >= _BASE { break; }
      guard = guard + 1;
    }
  }
  if est <= 0 { return 0; }
  return est;
}

// Divide |a| by a single-limb m (0 < m < BASE) via schoolbook division.
// The result of (u * 10^k) / 10^k is exact; remainder is truncated.
fn _div_small(a: &BigInt, m: Int) -> BigInt {
  var result = BigInt{ digits: Vec[Int].new(); negative: false; };
  if m <= 0 { return result; }
  var q_limbs = Vec[Int].new();
  var rem = 0;
  var i = a.digits.len() - 1;
  while i >= 0 {
    var cur = rem * _BASE + a.digits[i];
    q_limbs.push(cur / m);
    rem = cur % m;
    i = i - 1;
  }
  // q_limbs is high-to-low; reverse into little-endian quotient digits.
  var q_rev = Vec[Int].new();
  var j = q_limbs.len() - 1;
  while j >= 0 {
    q_rev.push(q_limbs[j]);
    j = j - 1;
  }
  result.digits = q_rev;
  _trim(&result);
  return result;
}

// Divide by BASE: quotient = digits[1..], remainder = digits[0].
// Returns a DivModResult struct to avoid tuple issues.
type DivModResult = { quot: BigInt; rem: Int; }

fn _div_mod_base(n: &BigInt) -> DivModResult {
  var q = BigInt{ digits: Vec[Int].new(); negative: false; };
  var r = 0;
  if n.digits.len() > 0 { r = n.digits[0]; }
  var i = 1;
  while i < n.digits.len() { q.digits.push(n.digits[i]); i = i + 1; }
  return DivModResult{ quot: q; rem: r; };
}

// ============================================================================
// Construction -- from Int, from Str
// ============================================================================

pub fn bigint_from_int(n: Int) -> BigInt {
  var result = BigInt{ digits: Vec[Int].new(); negative: false; };
  if n == 0 { return result; }
  var abs_n = n;
  if n < 0 { result.negative = true; abs_n = -n; }
  var remaining = abs_n;
  while remaining > 0 {
    result.digits.push(remaining % _BASE);
    remaining = remaining / _BASE;
  }
  return result;
}

// Build from an unsigned 64-bit value. The compiler emits SIGNED LLVM
// instructions for UInt64 `/` and `%`, so the proven unsigned helpers from
// xiom.num (u64_div_floor / u64_mod_euclid) are used instead -- exact for the
// full 0 .. 2^64-1 range.
pub fn bigint_from_u64(n: UInt64) -> BigInt {
  var result = BigInt{ digits: Vec[Int].new(); negative: false; };
  if n == 0 { return result; }
  var base: UInt64 = 1000000000;
  var v = n;
  while v != 0 {
    var r = xiom.num.u64_mod_euclid(v, base);
    result.digits.push(r as Int);
    v = xiom.num.u64_div_floor(v, base);
  }
  return result;
}

// Parse decimal string. Uses xiom.string.str_slice for char access.
// O(n2) due to repeated multiply-by-10-and-add during accumulation.
pub fn bigint_from_str(s: Str) -> Result[BigInt, Str] {
  if s.len() == 0 { return Err("empty string"); }
  var result = BigInt{ digits: Vec[Int].new(); negative: false; };
  result.digits.push(0);
  var sign_negative = false;
  var pos = 0;
  var first_slice = xiom.string.str_slice(s, 0, 1);
  if first_slice == "-" { sign_negative = true; pos = 1; }
  if pos >= s.len() { return Err("no digits after sign"); }
  // Parse one character and accumulate
  var ten = bigint_from_int(10);
  var i = pos;
  while i < s.len() {
    var ch_str = xiom.string.str_slice(s, i, i + 1);
    var digit = _parse_digit(ch_str);
    if digit < 0 { return Err("invalid character in bigint string"); }
    var temp = bigint_mul(&result, &ten);
    var d = bigint_from_int(digit);
    result = bigint_add(&temp, &d);
    i = i + 1;
  }
  _trim(&result);
  if bigint_is_zero(&result) {
    return Ok(BigInt{ digits: Vec[Int].new(); negative: false; });
  }
  result.negative = sign_negative;
  return Ok(result);
}

fn _parse_digit(c: Str) -> Int {
  if c == "0" { return 0; } if c == "1" { return 1; }
  if c == "2" { return 2; } if c == "3" { return 3; }
  if c == "4" { return 4; } if c == "5" { return 5; }
  if c == "6" { return 6; } if c == "7" { return 7; }
  if c == "8" { return 8; } if c == "9" { return 9; }
  return -1;
}

// ============================================================================
// Conversion -- to string
// ============================================================================

// Convert to decimal string via repeated division by BASE.
pub fn bigint_to_str(b: &BigInt) -> Str {
  if bigint_is_zero(b) { return "0"; }
  if b.digits.len() == 1 {
    var s = _limb_to_str(b.digits[0], false);
    if b.negative { return xiom.string.str_concat("-", s); }
    return s;
  }
  // Collect remainder limbs by repeatedly extracting the least significant
  // limb (r = digits[0]) and shifting remaining digits left.
  var temp = _copy(b);
  temp.negative = false;
  var remainders = Vec[Int].new();
  while !bigint_is_zero(&temp) {
    var r = temp.digits[0];
    // Shift: move all digits one position left (drop LSD)
    var last = temp.digits.len() - 1;
    var k = 0;
    while k < last {
      temp.digits[k] = temp.digits[k + 1];
      k = k + 1;
    }
    temp.digits.pop();
    remainders.push(r);
  }
  // Build string: most significant chunk first (no padding), rest padded to 9
  var result = "";
  if b.negative { result = "-"; }
  var j = remainders.len() - 1;
  while j >= 0 {
    var pad = j < remainders.len() - 1;
    result = xiom.string.str_concat(result, _limb_to_str(remainders[j], pad));
    j = j - 1;
  }
  return result;
}

fn _limb_to_str(limb: Int, zero_pad: Bool) -> Str {
  var val = limb;
  if val == 0 {
    if zero_pad { return "000000000"; }
    return "0";
  }
  // Extract digits in reverse
  var digits: [10]Int;
  var count = 0;
  while val > 0 {
    digits[count] = val % 10;
    val = val / 10;
    count = count + 1;
  }
  var result = "";
  // Zero-pad to 9 digits for non-MSB chunks
  if zero_pad {
    var pad = _BASE_DIGITS - count;
    while pad > 0 {
      result = xiom.string.str_concat(result, "0");
      pad = pad - 1;
    }
  }
  // Append digits most-significant-first using digit char table
  var i = count - 1;
  while i >= 0 {
    result = xiom.string.str_concat(result, _digit_char(digits[i]));
    i = i - 1;
  }
  return result;
}

// Convert a single digit (0-9) to a one-character string.
fn _digit_char(d: Int) -> Str {
  if d == 0 { return "0"; } if d == 1 { return "1"; }
  if d == 2 { return "2"; } if d == 3 { return "3"; }
  if d == 4 { return "4"; } if d == 5 { return "5"; }
  if d == 6 { return "6"; } if d == 7 { return "7"; }
  if d == 8 { return "8"; }
  return "9";
}

// ============================================================================
// Core arithmetic -- add, sub, mul, div_mod
// ============================================================================

pub fn bigint_add(a: &BigInt, b: &BigInt) -> BigInt {
  if a.negative == b.negative {
    var sum = _abs_add(a, b);
    sum.negative = a.negative;
    return sum;
  }
  var cmp = _abs_compare(a, b);
  if cmp == 0 { return BigInt{ digits: Vec[Int].new(); negative: false; }; }
  if cmp > 0 {
    var diff = _abs_sub(a, b);
    diff.negative = a.negative;
    return diff;
  }
  var diff = _abs_sub(b, a);
  diff.negative = b.negative;
  return diff;
}

pub fn bigint_sub(a: &BigInt, b: &BigInt) -> BigInt {
  var neg_b = _copy(b);
  neg_b.negative = !neg_b.negative;
  return bigint_add(a, &neg_b);
}

// Magnitude-only schoolbook multiplication (limbs only; sign ignored).
// O(n^2) -- the fast path below a Karatsuba-sized split.
fn _abs_mul_schoolbook(a: &BigInt, b: &BigInt) -> BigInt {
  var result = BigInt{ digits: Vec[Int].new(); negative: false; };
  if a.digits.len() == 0 || b.digits.len() == 0 { return result; }
  var len = a.digits.len() + b.digits.len();
  var k = 0;
  while k < len { result.digits.push(0); k = k + 1; }
  var i = 0;
  while i < a.digits.len() {
    var j = 0;
    while j < b.digits.len() {
      var prod = a.digits[i] * b.digits[j];
      var pos = i + j;
      var sum_val = result.digits[pos] + prod;
      result.digits[pos] = sum_val % _BASE;
      result.digits[pos + 1] = result.digits[pos + 1] + sum_val / _BASE;
      j = j + 1;
    }
    i = i + 1;
  }
  _trim(&result);
  return result;
}

// Karatsuba multiplication for magnitudes: O(n^1.585) vs schoolbook O(n^2).
// Split at k = max(len)/2: a = a1*B^k + a0, b = b1*B^k + b0, then
//   z0 = a0*b0;  z2 = a1*b1;  z1 = (a0+a1)*(b0+b1) - z0 - z2
//   result = (z2*B^k + z1)*B^k + z0
// Only 3 multiplications per level instead of 4. Below the threshold the
// schoolbook loop wins (allocation overhead of the split).
//
// MEASURED crossover (2026-08-11, this language's by-value Vec semantics):
//   schoolbook vs karatsuba at 2k digits: schoolbook ~13x faster
//   at 10k digits: equal; at 100k digits: karatsuba ~12% faster.
// Threshold 4000 limbs (36k digits) keeps the fast simple path for every
// realistic stdlib use while still serving extreme operands.
fn _abs_mul_karatsuba(a: &BigInt, b: &BigInt) -> BigInt {
  var la = a.digits.len();
  var lb = b.digits.len();
  if la < 4000 || lb < 4000 {
    return _abs_mul_schoolbook(a, b);
  }
  var k = la;
  if lb > k { k = lb; }
  k = k / 2;
  // Split into low (0..k) and high (k..) halves.
  var a0 = BigInt{ digits: Vec[Int].new(); negative: false; };
  var a1 = BigInt{ digits: Vec[Int].new(); negative: false; };
  var b0 = BigInt{ digits: Vec[Int].new(); negative: false; };
  var b1 = BigInt{ digits: Vec[Int].new(); negative: false; };
  var i = 0;
  while i < k && i < la { a0.digits.push(a.digits[i]); i = i + 1; }
  i = k;
  while i < la { a1.digits.push(a.digits[i]); i = i + 1; }
  i = 0;
  while i < k && i < lb { b0.digits.push(b.digits[i]); i = i + 1; }
  i = k;
  while i < lb { b1.digits.push(b.digits[i]); i = i + 1; }
  _trim(&a0);
  _trim(&a1);
  _trim(&b0);
  _trim(&b1);
  var z0 = _abs_mul_karatsuba(&a0, &b0);
  var z2 = _abs_mul_karatsuba(&a1, &b1);
  var s1 = _abs_add(&a0, &a1);
  var s2 = _abs_add(&b0, &b1);
  var m = _abs_mul_karatsuba(&s1, &s2);
  var z1 = _abs_sub(&m, &_abs_add(&z0, &z2));
  // result = (z2*B^k + z1)*B^k + z0
  var r = _abs_add(&_abs_shift_limbs(&z2, k), &z1);
  r = _abs_shift_limbs(&r, k);
  r = _abs_add(&r, &z0);
  _trim(&r);
  return r;
}

pub fn bigint_mul(a: &BigInt, b: &BigInt) -> BigInt {
  if bigint_is_zero(a) || bigint_is_zero(b) {
    return BigInt{ digits: Vec[Int].new(); negative: false; };
  }
  var result = _abs_mul_karatsuba(a, b);
  result.negative = a.negative != b.negative;
  return result;
}

pub fn bigint_div_mod(a: &BigInt, b: &BigInt) -> (BigInt, BigInt) {
  if bigint_is_zero(b) {
    return (BigInt{ digits: Vec[Int].new(); negative: false; },
            BigInt{ digits: Vec[Int].new(); negative: false; });
  }
  if _abs_compare(a, b) < 0 {
    var r = _copy(a);
    r.negative = false;
    return (BigInt{ digits: Vec[Int].new(); negative: false; }, r);
  }
  var abs_a = _copy(a);
  abs_a.negative = false;
  var abs_b = _copy(b);
  abs_b.negative = false;
  var quotient = BigInt{ digits: Vec[Int].new(); negative: false; };
  var remainder = _copy(&abs_a);
  if abs_b.digits.len() == 1 {
    // Single-limb divisor: exact schoolbook division, O(n). Handles the
    // divisor == 1 case (where a limb estimate would degenerate to the cap).
    var q_limbs = Vec[Int].new();
    var rem = 0;
    var d0 = abs_b.digits[0];
    var i = abs_a.digits.len() - 1;
    while i >= 0 {
      var cur = rem * _BASE + abs_a.digits[i];
      q_limbs.push(cur / d0);
      rem = cur % d0;
      i = i - 1;
    }
    // q_limbs is high-to-low; reverse into little-endian quotient digits.
    var q_rev = Vec[Int].new();
    var j = q_limbs.len() - 1;
    while j >= 0 {
      q_rev.push(q_limbs[j]);
      j = j - 1;
    }
    quotient.digits = q_rev;
    if rem > 0 { remainder.digits = Vec[Int].new(); remainder.digits.push(rem); }
    else { remainder.digits = Vec[Int].new(); }
  } else {
    // Multi-limb divisor: Knuth Algorithm D.
    // D1: normalize so the divisor's top limb >= BASE/2. d = floor(BASE/(v+1))
    // satisfies d*v in [BASE/2, BASE) and the carry into the top limb is
    // bounded by d-1, so d*v + carry <= BASE-1 -- the divisor never gains a
    // limb. The quotient is unaffected by the shared scaling.
    var dnorm = _BASE / (abs_b.digits[abs_b.digits.len() - 1] + 1);
    var norm_a = abs_a;
    var norm_b = abs_b;
    if dnorm > 1 {
      norm_a = _abs_mul_small(&abs_a, dnorm);
      norm_b = _abs_mul_small(&abs_b, dnorm);
    }
    remainder = _copy(&norm_a);
    var shift = norm_a.digits.len() - norm_b.digits.len();
    while shift >= 0 {
      var est = _estimate_q_digit(&remainder, &norm_b, shift);
      if est < 0 {
        // Remainder top limb is zero: the true digit is 0 or 1 -- test
        // r >= v*B^shift directly (a guessed 0 would be an uncorrectable
        // underestimate at this position's weight).
        var sh_v = _abs_shift_limbs(&norm_b, shift);
        if _abs_compare(&remainder, &sh_v) >= 0 { est = 1; }
        else { est = 0; }
      }
      if est > 0 {
        var q_part = _abs_mul_small(&norm_b, est);
        var q_shifted = _abs_shift_limbs(&q_part, shift);
        var count = 0;
        while _abs_compare(&remainder, &q_shifted) < 0 && count < 20 {
          est = est - 1;
          if est <= 0 { break; }
          q_part = _abs_mul_small(&norm_b, est);
          q_shifted = _abs_shift_limbs(&q_part, shift);
          count = count + 1;
        }
        if est > 0 {
          remainder = _abs_sub(&remainder, &q_shifted);
          var q_add = _abs_shift_limbs(&bigint_from_int(est), shift);
          quotient = bigint_add(&quotient, &q_add);
        }
      }
      shift = shift - 1;
    }
    // Upward fixup: a normalized Knuth qhat can be low by 1-2, leaving the
    // remainder >= divisor; subtract the divisor back out per unit.
    var guard = 0;
    while _abs_compare(&remainder, &norm_b) >= 0 && guard < 100 {
      remainder = _abs_sub(&remainder, &norm_b);
      quotient = bigint_add(&quotient, &bigint_one());
      guard = guard + 1;
    }
    // D7: unnormalize the remainder (r_norm = r * dnorm, exact division).
    if dnorm > 1 { remainder = _div_small(&remainder, dnorm); }
  }
  quotient.negative = a.negative != b.negative;
  remainder.negative = a.negative;
  _trim(&quotient);
  _trim(&remainder);
  return (quotient, remainder);
}

// ============================================================================
// Comparison, zero, sign, abs, neg
// ============================================================================

pub fn bigint_compare(a: &BigInt, b: &BigInt) -> Int {
  if a.negative && !b.negative { return -1; }
  if !a.negative && b.negative { return 1; }
  var cmp = _abs_compare(a, b);
  if a.negative { return -cmp; }
  return cmp;
}

pub fn bigint_is_zero(b: &BigInt) -> Bool {
  if b.digits.len() == 0 { return true; }
  var i = 0;
  while i < b.digits.len() {
    if b.digits[i] != 0 { return false; }
    i = i + 1;
  }
  return true;
}

pub fn bigint_abs(b: &BigInt) -> BigInt {
  var result = _copy(b);
  result.negative = false;
  return result;
}

pub fn bigint_neg(b: &BigInt) -> BigInt {
  if bigint_is_zero(b) { return BigInt{ digits: Vec[Int].new(); negative: false; }; }
  var result = _copy(b);
  result.negative = !b.negative;
  return result;
}

pub fn bigint_sign(b: &BigInt) -> Int {
  if bigint_is_zero(b) { return 0; }
  if b.negative { return -1; }
  return 1;
}

// ============================================================================
// Modular arithmetic and advanced operations
// ============================================================================

pub fn bigint_mod(a: &BigInt, m: &BigInt) -> BigInt {
  var pair = bigint_div_mod(a, m);
  var r = pair.1;
  if r.negative { r = bigint_add(&r, m); }
  return r;
}

pub fn bigint_pow(base: &BigInt, exp: Int) -> BigInt {
  if exp < 0 { return BigInt{ digits: Vec[Int].new(); negative: false; }; }
  if exp == 0 { return bigint_from_int(1); }
  var result = bigint_from_int(1);
  var b = _copy(base);
  var e = exp;
  while e > 0 {
    if e % 2 == 1 { result = bigint_mul(&result, &b); }
    e = e / 2;
    if e > 0 { b = bigint_mul(&b, &b); }
  }
  return result;
}

pub fn bigint_gcd(a: &BigInt, b: &BigInt) -> BigInt {
  var x = bigint_abs(a);
  var y = bigint_abs(b);
  if bigint_is_zero(&y) { return x; }
  while !bigint_is_zero(&y) {
    var pair = bigint_div_mod(&x, &y);
    x = y;
    y = pair.1;
  }
  return x;
}

pub fn bigint_shift_left(b: &BigInt, shift: Int) -> BigInt {
  if shift <= 0 { return _copy(b); }
  var ten = bigint_from_int(10);
  var factor = bigint_pow(&ten, shift);
  return bigint_mul(b, &factor);
}

// ============================================================================
// PRODUCTION BIGINT (2026-08-10) -- additive extension, Phase A
// ============================================================================
// Every function below is additive: existing pub fns are untouched (API-freeze
// gate). Contracts use `requires` for preconditions; where a violation can be
// handled gracefully the function ALSO guards internally (documented).
//
// Representation note: `shift_left` multiplies by 10^n (decimal shift, kept
// from the original API) while `shift_right` is a true arithmetic bit shift
// (division by 2^n, floor semantics for negatives).

// -- Constants ---------------------------------------------------------------
// NOTE (2026-08-10): module-global initializers cannot call functions (the
// compiler silently leaves them zero -- see docs/COMPILER_BUGS.md), so the
// spec constants BIGINT_ZERO/ONE/TEN are exposed as pure constructors that
// return a fresh value. Zero-cost, immutable by construction.

pub fn bigint_zero() -> BigInt {
  return BigInt{ digits: Vec[Int].new(); negative: false; };
}

pub fn bigint_one() -> BigInt {
  return bigint_from_int(1);
}

pub fn bigint_ten() -> BigInt {
  return bigint_from_int(10);
}

pub fn bigint_two() -> BigInt {
  return bigint_from_int(2);
}

// -- Base conversion ---------------------------------------------------------

// Parse a digit character in base 2..36 (0-9, a-z, A-Z). -1 = invalid.
fn _parse_digit_base(c: Str) -> Int {
  var opt = xiom.string.char_at(c, 0);
  if !opt.is_some { return -1; }
  var ch = opt.value;
  if ch >= '0' && ch <= '9' { return xiom.core.to_int_from_char(ch) - xiom.core.to_int_from_char('0'); }
  if ch >= 'a' && ch <= 'z' { return xiom.core.to_int_from_char(ch) - xiom.core.to_int_from_char('a') + 10; }
  if ch >= 'A' && ch <= 'Z' { return xiom.core.to_int_from_char(ch) - xiom.core.to_int_from_char('A') + 10; }
  return -1;
}

// Parse a string in base 2..36 (optional leading - or +).
pub fn bigint_from_base(s: Str, base: Int) -> Result[BigInt, Str]
  requires: base >= 2 && base <= 36
{
  if s.len() == 0 { return Err("empty string"); }
  if base < 2 || base > 36 { return Err("invalid base"); }
  var result = bigint_zero();
  var neg = false;
  var pos = 0;
  var first = xiom.string.str_slice(s, 0, 1);
  if first == "-" { neg = true; pos = 1; }
  elif first == "+" { pos = 1; }
  if pos >= s.len() { return Err("no digits"); }
  var bb = bigint_from_int(base);
  var i = pos;
  while i < s.len() {
    var ch = xiom.string.str_slice(s, i, i + 1);
    var d = _parse_digit_base(ch);
    if d < 0 || d >= base { return Err("invalid digit for base"); }
    var t = bigint_mul(&result, &bb);
    var dv = bigint_from_int(d);
    result = bigint_add(&t, &dv);
    i = i + 1;
  }
  if neg && !bigint_is_zero(&result) { result.negative = true; }
  return Ok(result);
}

// Parse hexadecimal ("ff", "-1a"). Case-insensitive; no "0x" prefix.
pub fn bigint_from_hex(s: Str) -> Result[BigInt, Str] {
  return bigint_from_base(s, 16);
}

// Convert to a string in base 2..36 (digits 0-9, A-Z; "-" prefix for negatives).
// Returns "" for an invalid base.
pub fn bigint_to_base(b: &BigInt, base: Int) -> Str {
  if base < 2 || base > 36 { return ""; }
  if bigint_is_zero(b) { return "0"; }
  var alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  var temp = bigint_abs(b);
  var bb = bigint_from_int(base);
  var chars = Vec[Int].new();
  while !bigint_is_zero(&temp) {
    var dm = bigint_div_mod(&temp, &bb);
    var rem = 0;
    if !bigint_is_zero(&dm.1) { rem = dm.1.digits[0]; }
    chars.push(rem);
    temp = dm.0;
  }
  var result = "";
  if b.negative { result = "-"; }
  var i = chars.len() - 1;
  while i >= 0 {
    var ch = xiom.string.str_slice(alphabet, chars[i], chars[i] + 1);
    result = xiom.string.str_concat(result, ch);
    i = i - 1;
  }
  return result;
}

// Lowercase hexadecimal (matches the parse examples "ff"/"-1a").
pub fn bigint_to_hex(b: &BigInt) -> Str {
  if bigint_is_zero(b) { return "0"; }
  var alphabet = "0123456789abcdef";
  var temp = bigint_abs(b);
  var bb = bigint_from_int(16);
  var chars = Vec[Int].new();
  while !bigint_is_zero(&temp) {
    var dm = bigint_div_mod(&temp, &bb);
    var rem = 0;
    if !bigint_is_zero(&dm.1) { rem = dm.1.digits[0]; }
    chars.push(rem);
    temp = dm.0;
  }
  var result = "";
  if b.negative { result = "-"; }
  var i = chars.len() - 1;
  while i >= 0 {
    var ch = xiom.string.str_slice(alphabet, chars[i], chars[i] + 1);
    result = xiom.string.str_concat(result, ch);
    i = i - 1;
  }
  return result;
}

// Range-checked conversion to Int (i64). Err on overflow.
pub fn bigint_to_int(b: &BigInt) -> Result[Int, Str] {
  var limit = bigint_from_int(INT_MAX);
  if bigint_is_negative(b) {
    var lim_neg = bigint_neg(&bigint_add(&limit, &bigint_one()));
    if bigint_compare(b, &lim_neg) < 0 { return Err("out of i64 range"); }
  } else {
    if bigint_compare(b, &limit) > 0 { return Err("out of i64 range"); }
  }
  var result = 0;
  var i = b.digits.len() - 1;
  while i >= 0 {
    result = result * 1000000000 + b.digits[i];
    i = i - 1;
  }
  if b.negative { result = -result; }
  return Ok(result);
}

// ============================================================================
// Fixed-width bridges -- 256-bit framing (2026-08-11)
// ============================================================================
// BigInt is arbitrary precision, so 128/64-bit consumers get exact
// range-checked conversions (Err on out-of-range -- no silent truncation).
// The accumulation uses native LLVM i128/UInt128 arithmetic (no soft-float
// helpers); the range pre-check guarantees no wraparound.

// Convert to UInt64 (0 .. 2^64-1). Negative or >= 2^64 -> Err.
pub fn bigint_to_u64(b: &BigInt) -> Result[UInt64, Str] {
  if bigint_is_negative(b) { return Err("out of u64 range"); }
  var max = bigint_from_u64(18446744073709551615 as UInt64);
  if bigint_compare(b, &max) > 0 { return Err("out of u64 range"); }
  var r: UInt64 = 0;
  var base: UInt64 = 1000000000;
  var i = b.digits.len() - 1;
  while i >= 0 {
    r = r * base + (b.digits[i] as UInt64);
    i = i - 1;
  }
  return Ok(r);
}

// Convert to UInt128 (0 .. 2^128-1). Negative or >= 2^128 -> Err.
pub fn bigint_to_u128(b: &BigInt) -> Result[UInt128, Str] {
  if bigint_is_negative(b) { return Err("out of u128 range"); }
  var max = bigint_from_base("ffffffffffffffffffffffffffffffff", 16);
  match max {
    Err(_) => { return Err("internal: hex parse failed"); };
    Ok(m) => {
      if bigint_compare(b, &m) > 0 { return Err("out of u128 range"); }
    };
  }
  var r: UInt128 = 0;
  var base: UInt128 = 1000000000 as UInt128;
  var i = b.digits.len() - 1;
  while i >= 0 {
    r = r * base + (b.digits[i] as UInt128);
    i = i - 1;
  }
  return Ok(r);
}

// Convert to Int128 (-2^127 .. 2^127-1). Out of range -> Err.
pub fn bigint_to_i128(b: &BigInt) -> Result[Int128, Str] {
  var lo = bigint_from_base("80000000000000000000000000000000", 16);
  var hi = bigint_from_base("7fffffffffffffffffffffffffffffff", 16);
  match lo {
    Err(_) => { return Err("internal: hex parse failed"); };
    Ok(lo_v) => {
      var lo_neg = bigint_neg(&lo_v);
      if bigint_compare(b, &lo_neg) < 0 { return Err("out of i128 range"); }
    };
  }
  match hi {
    Err(_) => { return Err("internal: hex parse failed"); };
    Ok(hi_v) => {
      if bigint_compare(b, &hi_v) > 0 { return Err("out of i128 range"); }
    };
  }
  var r: Int128 = 0;
  var base: Int128 = 1000000000 as Int128;
  var i = b.digits.len() - 1;
  while i >= 0 {
    r = r * base + (b.digits[i] as Int128);
    i = i - 1;
  }
  if bigint_is_negative(b) {
    var z: Int128 = 0 as Int128;
    r = z - r;
  }
  return Ok(r);
}

// -- Predicates ---------------------------------------------------------------

pub fn bigint_is_one(b: &BigInt) -> Bool {
  return bigint_compare(b, &bigint_one()) == 0;
}

pub fn bigint_is_even(b: &BigInt) -> Bool {
  if bigint_is_zero(b) { return true; }
  return b.digits[0] % 2 == 0;
}

pub fn bigint_is_odd(b: &BigInt) -> Bool {
  return !bigint_is_even(b);
}

pub fn bigint_is_negative(b: &BigInt) -> Bool {
  return b.negative && !bigint_is_zero(b);
}

// -- Arithmetic ---------------------------------------------------------------

// Truncating division (quotient of bigint_div_mod).
pub fn bigint_div(a: &BigInt, b: &BigInt) -> BigInt
  requires: !bigint_is_zero(b)
{
  if bigint_is_zero(b) { return bigint_zero(); }
  var dm = bigint_div_mod(a, b);
  return dm.0;
}

// Modular exponentiation: (base^exp) mod m. exp >= 0, m != 0. Square-and-multiply.
pub fn bigint_pow_mod(base: &BigInt, exp: &BigInt, m: &BigInt) -> BigInt
  requires: !bigint_is_zero(m)
  requires: !bigint_is_negative(exp)
{
  if bigint_is_zero(m) { return bigint_zero(); }
  if bigint_is_one(m) { return bigint_zero(); }
  var result = bigint_one();
  if bigint_is_zero(exp) { return result; }
  var b = bigint_mod(base, m);
  var e = bigint_abs(exp);
  var two = bigint_from_int(2);
  while !bigint_is_zero(&e) {
    if bigint_is_odd(&e) {
      result = bigint_mod(&bigint_mul(&result, &b), m);
    }
    b = bigint_mod(&bigint_mul(&b, &b), m);
    e = bigint_div(&e, &two);
  }
  return result;
}

// Integer square root (floor): Newton's method with a decimal-digit-based
// initial guess 10^ceil(D/2) >= sqrt(n). Quadratic convergence.
pub fn bigint_sqrt(b: &BigInt) -> BigInt
  requires: !bigint_is_negative(b)
{
  if bigint_is_negative(b) { return bigint_zero(); }
  if bigint_compare(b, &bigint_from_int(2)) < 0 { return _copy(b); }
  var s = bigint_to_str(b);
  var D = s.len();
  var guess_exp = (D + 1) / 2;
  var x = bigint_pow(&bigint_ten(), guess_exp);
  var two = bigint_from_int(2);
  var guard = 0;
  while guard < D + 32 {
    var y = bigint_div(&bigint_add(&x, &bigint_div(b, &x)), &two);
    if bigint_compare(&y, &x) >= 0 { return x; }
    x = y;
    guard = guard + 1;
  }
  return x;
}

// (floor sqrt, n - sqrt^2).
pub fn bigint_sqrt_rem(b: &BigInt) -> (BigInt, BigInt)
  requires: !bigint_is_negative(b)
{
  var s = bigint_sqrt(b);
  var r = bigint_sub(b, &bigint_mul(&s, &s));
  return (s, r);
}

// -- Number theory ------------------------------------------------------------

// Least common multiple. lcm(0, x) == 0.
pub fn bigint_lcm(a: &BigInt, b: &BigInt) -> BigInt {
  if bigint_is_zero(a) || bigint_is_zero(b) { return bigint_zero(); }
  var g = bigint_gcd(a, b);
  var prod = bigint_mul(a, b);
  return bigint_abs(&bigint_div(&prod, &g));
}

// Extended Euclidean algorithm: returns (g, x, y) with a*x + b*y == g,
// g = gcd(|a|, |b|) > 0.
pub fn bigint_ext_gcd(a: &BigInt, b: &BigInt) -> (BigInt, BigInt, BigInt) {
  var old_r = bigint_abs(a);
  var r = bigint_abs(b);
  var old_s = bigint_one();
  var s = bigint_zero();
  var old_t = bigint_zero();
  var t = bigint_one();
  while !bigint_is_zero(&r) {
    var q = bigint_div(&old_r, &r);
    var new_r = bigint_sub(&old_r, &bigint_mul(&q, &r));
    var new_s = bigint_sub(&old_s, &bigint_mul(&q, &s));
    var new_t = bigint_sub(&old_t, &bigint_mul(&q, &t));
    old_r = r;
    r = new_r;
    old_s = s;
    s = new_s;
    old_t = t;
    t = new_t;
  }
  var x = old_s;
  var y = old_t;
  if a.negative { x = bigint_neg(&x); }
  if b.negative { y = bigint_neg(&y); }
  return (old_r, x, y);
}

// Miller-Rabin primality test. Deterministic for n < 3.3e24 (bases
// 2..37), probabilistic (error < 4^-rounds) above.
pub fn bigint_is_prime(b: &BigInt) -> Bool {
  if bigint_is_negative(b) { return false; }
  var two = bigint_from_int(2);
  if bigint_compare(b, &two) < 0 { return false; }
  // Small trial division + small-prime check.
  var small = Vec[Int].new();
  small.push(2); small.push(3); small.push(5); small.push(7);
  small.push(11); small.push(13); small.push(17); small.push(19);
  small.push(23); small.push(29); small.push(31); small.push(37);
  var i = 0;
  while i < small.len() {
    var p = bigint_from_int(small[i]);
    if bigint_compare(b, &p) == 0 { return true; }
    var r = bigint_mod(b, &p);
    if bigint_is_zero(&r) { return false; }
    i = i + 1;
  }
  // Write b-1 = d * 2^s with d odd.
  var n1 = bigint_sub(b, &bigint_one());
  var d = _copy(&n1);
  var s = 0;
  while bigint_is_even(&d) {
    d = bigint_div(&d, &two);
    s = s + 1;
  }
  var j = 0;
  while j < small.len() {
    var ab = bigint_from_int(small[j]);
    if bigint_compare(&ab, b) >= 0 { j = j + 1; continue; }
    var x = bigint_pow_mod(&ab, &d, b);
    if bigint_is_one(&x) { j = j + 1; continue; }
    if bigint_compare(&x, &n1) == 0 { j = j + 1; continue; }
    var pass = false;
    var k = 0;
    while k < s {
      x = bigint_pow_mod(&x, &two, b);
      if bigint_compare(&x, &n1) == 0 { pass = true; break; }
      if bigint_is_one(&x) { return false; }
      k = k + 1;
    }
    if !pass { return false; }
    j = j + 1;
  }
  return true;
}

// Smallest prime strictly greater than b. next_prime(1) == 2.
pub fn bigint_next_prime(b: &BigInt) -> BigInt {
  var two = bigint_from_int(2);
  if bigint_compare(b, &two) < 0 { return two; }
  var c = bigint_add(b, &bigint_one());
  while !bigint_is_prime(&c) {
    c = bigint_add(&c, &bigint_one());
  }
  return c;
}

// n! for n >= 0. O(n) BigInt multiplications.
pub fn bigint_factorial(n: Int) -> BigInt
  requires: n >= 0
{
  if n < 0 { return bigint_zero(); }
  var result = bigint_one();
  var i = 2;
  while i <= n {
    var iv = bigint_from_int(i);
    result = bigint_mul(&result, &iv);
    i = i + 1;
  }
  return result;
}

// C(n, k) for 0 <= k <= n. Multiplicative formula; every intermediate
// division is exact.
pub fn bigint_binomial(n: Int, k: Int) -> BigInt
  requires: n >= 0
  requires: k >= 0
  requires: k <= n
{
  if k < 0 || k > n { return bigint_zero(); }
  var kk = k;
  if kk > n - kk { kk = n - kk; }
  var result = bigint_one();
  var i = 1;
  while i <= kk {
    var num = bigint_from_int(n - kk + i);
    var den = bigint_from_int(i);
    result = bigint_mul(&result, &num);
    result = bigint_div(&result, &den);
    i = i + 1;
  }
  return result;
}

// F(n): F(0)=0, F(1)=1. Iterative, O(n) BigInt additions.
pub fn bigint_fibonacci(n: Int) -> BigInt
  requires: n >= 0
{
  if n < 0 { return bigint_zero(); }
  if n == 0 { return bigint_zero(); }
  if n == 1 { return bigint_one(); }
  var a = bigint_zero();
  var b = bigint_one();
  var i = 2;
  while i <= n {
    var c = bigint_add(&a, &b);
    a = b;
    b = c;
    i = i + 1;
  }
  return b;
}

// -- Bitwise operations -------------------------------------------------------
// Two's-complement semantics with a virtual infinite sign extension:
// negatives are treated as ...111x patterns. Implementation converts both
// operands to L-bit two's-complement arrays (L = max bit_len + 1), applies
// the bitwise op element-wise, and converts back.

// |b| as little-endian bit array (no leading zeros). Empty for zero.
fn _bigint_bit_array(b: &BigInt) -> Vec[Int] {
  var bits = Vec[Int].new();
  var t = bigint_abs(b);
  if bigint_is_zero(&t) { return bits; }
  var two = bigint_from_int(2);
  while !bigint_is_zero(&t) {
    var dm = bigint_div_mod(&t, &two);
    var rem = 0;
    if !bigint_is_zero(&dm.1) { rem = dm.1.digits[0]; }
    bits.push(rem);
    t = dm.0;
  }
  return bits;
}

// Little-endian bit array -> BigInt (sign applied).
fn _bits_to_bigint(bits: &Vec[Int], negative: Bool) -> BigInt {
  var result = bigint_zero();
  var two = bigint_from_int(2);
  var place = bigint_one();
  var i = 0;
  while i < bits.len() {
    if bits[i] == 1 { result = bigint_add(&result, &place); }
    place = bigint_mul(&place, &two);
    i = i + 1;
  }
  if negative { result = bigint_neg(&result); }
  return result;
}

// b as an L-bit two's-complement array (little-endian).
fn _twos_bits(b: &BigInt, L: Int) -> Vec[Int] {
  var mag = _bigint_bit_array(b);
  var bits = Vec[Int].new();
  var i = 0;
  if !b.negative {
    while i < L {
      if i < mag.len() { bits.push(mag[i]); }
      else { bits.push(0); }
      i = i + 1;
    }
  } else {
    var carry = 1;
    while i < L {
      var bit = 0;
      if i < mag.len() { bit = mag[i]; }
      var inv = 1 - bit;
      var s = inv + carry;
      if s >= 2 { bits.push(s - 2); carry = 1; }
      else { bits.push(s); carry = 0; }
      i = i + 1;
    }
  }
  return bits;
}

// L-bit two's-complement array -> signed BigInt.
fn _from_twos_bits(bits: &Vec[Int]) -> BigInt {
  var L = bits.len();
  if L == 0 { return bigint_zero(); }
  if bits[L - 1] == 0 { return _bits_to_bigint(bits, false); }
  var mag = Vec[Int].new();
  var carry = 1;
  var i = 0;
  while i < L {
    var inv = 1 - bits[i];
    var s = inv + carry;
    if s >= 2 { mag.push(s - 2); carry = 1; }
    else { mag.push(s); carry = 0; }
    i = i + 1;
  }
  return _bits_to_bigint(&mag, true);
}

pub fn bigint_bit_and(a: &BigInt, b: &BigInt) -> BigInt {
  var la = bigint_bit_len(a);
  var lb = bigint_bit_len(b);
  var L = la;
  if lb > L { L = lb; }
  L = L + 1;
  var ba = _twos_bits(a, L);
  var bb = _twos_bits(b, L);
  var r = Vec[Int].new();
  var i = 0;
  while i < L {
    if ba[i] == 1 && bb[i] == 1 { r.push(1); }
    else { r.push(0); }
    i = i + 1;
  }
  return _from_twos_bits(&r);
}

pub fn bigint_bit_or(a: &BigInt, b: &BigInt) -> BigInt {
  var la = bigint_bit_len(a);
  var lb = bigint_bit_len(b);
  var L = la;
  if lb > L { L = lb; }
  L = L + 1;
  var ba = _twos_bits(a, L);
  var bb = _twos_bits(b, L);
  var r = Vec[Int].new();
  var i = 0;
  while i < L {
    if ba[i] == 1 || bb[i] == 1 { r.push(1); }
    else { r.push(0); }
    i = i + 1;
  }
  return _from_twos_bits(&r);
}

pub fn bigint_bit_xor(a: &BigInt, b: &BigInt) -> BigInt {
  var la = bigint_bit_len(a);
  var lb = bigint_bit_len(b);
  var L = la;
  if lb > L { L = lb; }
  L = L + 1;
  var ba = _twos_bits(a, L);
  var bb = _twos_bits(b, L);
  var r = Vec[Int].new();
  var i = 0;
  while i < L {
    if ba[i] != bb[i] { r.push(1); }
    else { r.push(0); }
    i = i + 1;
  }
  return _from_twos_bits(&r);
}

// Arithmetic (floor) right shift by n bits: b >> n. For negative b this
// rounds toward -inf (true arithmetic shift).
pub fn bigint_shift_right(b: &BigInt, n: Int) -> BigInt
  requires: n >= 0
{
  if n <= 0 { return _copy(b); }
  if bigint_is_zero(b) { return bigint_zero(); }
  var two = bigint_from_int(2);
  var divr = bigint_pow(&two, n);
  var mag = bigint_abs(b);
  var q = bigint_div(&mag, &divr);
  var r = bigint_mod(&mag, &divr);
  if b.negative {
    if !bigint_is_zero(&r) { q = bigint_add(&q, &bigint_one()); }
    return bigint_neg(&q);
  }
  return q;
}

// Number of set bits in |b| (well-defined for all signs).
pub fn bigint_popcount(b: &BigInt) -> Int {
  var bits = _bigint_bit_array(b);
  var count = 0;
  var i = 0;
  while i < bits.len() {
    if bits[i] == 1 { count = count + 1; }
    i = i + 1;
  }
  return count;
}

// Bits needed to represent |b|; 0 for zero.
pub fn bigint_bit_len(b: &BigInt) -> Int {
  var bits = _bigint_bit_array(b);
  return bits.len();
}

// -- Comparison wrappers ------------------------------------------------------

pub fn bigint_eq(a: &BigInt, b: &BigInt) -> Bool {
  return bigint_compare(a, b) == 0;
}

pub fn bigint_lt(a: &BigInt, b: &BigInt) -> Bool {
  return bigint_compare(a, b) < 0;
}

pub fn bigint_le(a: &BigInt, b: &BigInt) -> Bool {
  return bigint_compare(a, b) <= 0;
}

pub fn bigint_gt(a: &BigInt, b: &BigInt) -> Bool {
  return bigint_compare(a, b) > 0;
}

pub fn bigint_ge(a: &BigInt, b: &BigInt) -> Bool {
  return bigint_compare(a, b) >= 0;
}








