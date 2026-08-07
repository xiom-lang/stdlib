// XIOM — Arbitrary-Precision Signed Integer (BigInt) Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.bigint

use xiom.string;

// ============================================================================
// Constants — base-10^9 representation
// ============================================================================

// Each limb stores 9 decimal digits (0 .. 999,999,999).
// Limbs are stored little-endian: index 0 is least significant.

var _BASE: Int = 1000000000;
var _BASE_DIGITS: Int = 9;

// ============================================================================
// Type — BigInt
// ============================================================================

pub type BigInt = { digits: Vec[Int]; negative: Bool; }

// ============================================================================
// Private helpers — trim, copy, comparison
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

fn _estimate_q_digit(n: &BigInt, d: &BigInt, shift: Int) -> Int {
  var idx = d.digits.len() - 1 + shift;
  if idx >= n.digits.len() { return 0; }
  var d_hi = d.digits[d.digits.len() - 1];
  if d_hi == 0 { return 0; }
  var n_hi = n.digits[idx];
  var est = n_hi / d_hi;
  if est <= 0 { return 1; }
  if est >= _BASE { return _BASE - 1; }
  return est;
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
// Construction — from Int, from Str
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

// Parse decimal string. Uses xiom.string.str_slice for char access.
// O(n²) due to repeated multiply-by-10-and-add during accumulation.
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
// Conversion — to string
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
// Core arithmetic — add, sub, mul, div_mod
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

pub fn bigint_mul(a: &BigInt, b: &BigInt) -> BigInt {
  if bigint_is_zero(a) || bigint_is_zero(b) {
    return BigInt{ digits: Vec[Int].new(); negative: false; };
  }
  var len = a.digits.len() + b.digits.len();
  var result = BigInt{ digits: Vec[Int].new(); negative: false; };
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
  var shift = abs_a.digits.len() - abs_b.digits.len();
  while shift >= 0 {
    var est = _estimate_q_digit(&remainder, &abs_b, shift);
    if est > 0 {
      var q_part = _abs_mul_small(&abs_b, est);
      var q_shifted = _abs_shift_limbs(&q_part, shift);
      var count = 0;
      while _abs_compare(&remainder, &q_shifted) < 0 && count < 10 {
        est = est - 1;
        if est <= 0 { break; }
        q_part = _abs_mul_small(&abs_b, est);
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
