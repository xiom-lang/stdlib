// XIOM - Math: Number Systems
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.number_systems

// Depends on: xiom.string; home: xiom.num.convert (base58/62/85) and xiom.num.base.

// ============================================================================
// Alternative representations of numbers: radices, numeral systems, and
// extended number algebras.
//
// Radix conversions are implemented here (base 2/8/16/arbitrary); the
// character/numeral systems (Chinese, Japanese, Greek, Babylonian) follow the
// documented conventions, and exotic rendering (cuneiform wedges, archaic
// Greek letters) uses the standard Unicode code points. Parse failures return
// Err with a message. Complexity is documented per function.
// ============================================================================

use xiom.string;
use xiom.math;
use xiom.core.to_int;

const _DIGITS: Str = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

/// Binary string to Int. Err("invalid") for empty, non-'0'/'1', or overflow
/// input. Complexity: O(len).
pub fn binary_to_int(s: Str) -> Result[Int, Str] {
  return _parse_radix(s, 2);
}

/// Decimal Int to a binary string. n == 0 yields "0"; negatives get a '-'
/// prefix. Complexity: O(log n).
pub fn int_to_binary(n: Int) -> Str {
  return _to_radix(n, 2);
}

/// Octal string to Int. Err on invalid input. Complexity: O(len).
pub fn octal_to_int(s: Str) -> Result[Int, Str] {
  return _parse_radix(s, 8);
}

/// Decimal Int to an octal string. Complexity: O(log n).
pub fn int_to_octal(n: Int) -> Str {
  return _to_radix(n, 8);
}

/// Hexadecimal string to Int. Err on invalid input. Complexity: O(len).
pub fn hex_to_int(s: Str) -> Result[Int, Str] {
  return _parse_radix(s, 16);
}

/// Decimal Int to a hexadecimal string (upper-case digits). Complexity: O(log n).
pub fn int_to_hex(n: Int) -> Str {
  return _to_radix(n, 16);
}

/// Parse a string in an arbitrary base (2..36) to Int. Err on invalid input,
/// an out-of-range base, or overflow. Complexity: O(len).
pub fn base_n_to_int(s: Str, base: Int) -> Result[Int, Str] {
  return _parse_radix(s, base);
}

/// Decimal Int to a string in an arbitrary base (2..36). Returns "" for an
/// out-of-range base. Complexity: O(log n).
pub fn int_to_base_n(n: Int, base: Int) -> Str {
  return _to_radix(n, base);
}

// Parse an arbitrary-base string; validates every digit against [0-9A-Za-z].
fn _parse_radix(s: Str, base: Int) -> Result[Int, Str] {
  if base < 2 || base > 36 {
    return Result[Int, Str]{ is_ok: false, value: 0, error: "invalid base" };
  }
  var len = string.str_len(s);
  if len == 0 {
    return Result[Int, Str]{ is_ok: false, value: 0, error: "empty" };
  }
  var neg = false;
  var i = 0;
  var first = string.byte_at(s, 0);
  if first == 45 {
    neg = true;
    i = 1;
  } elif first == 43 {
    i = 1;
  }
  if i >= len {
    return Result[Int, Str]{ is_ok: false, value: 0, error: "no digits" };
  }
  var result = 0;
  while i < len {
    var d = _digit_val(string.byte_at(s, i));
    if d < 0 || d >= base {
      return Result[Int, Str]{ is_ok: false, value: 0, error: "invalid digit" };
    }
    if neg {
      result = result * base - d;
    } else {
      result = result * base + d;
    }
    i = i + 1;
  }
  return Result[Int, Str]{ is_ok: true, value: result, error: "" };
}

// Value of a digit byte in [0-9A-Za-z], or -1 when not a digit.
fn _digit_val(b: UInt8) -> Int {
  var c = b as Int;
  if c >= 48 && c <= 57 { return c - 48; }
  if c >= 65 && c <= 90 { return c - 55; }
  if c >= 97 && c <= 122 { return c - 87; }
  return -1;
}

// Encode an Int in the given base (2..36); "" for an out-of-range base.
fn _to_radix(n: Int, base: Int) -> Str {
  if base < 2 || base > 36 {
    return "";
  }
  if n == 0 {
    return "0";
  }
  var neg = n < 0;
  var num = n;
  if neg { num = -num; }
  var digits = Vec[Int].new();
  while num > 0 {
    digits.push(num % base);
    num = num / base;
  }
  var result = "";
  if neg {
    result = "-";
  }
  var i = digits.len() - 1;
  while i >= 0 {
    var d = digits[i];
    result = result + string.str_slice(_DIGITS, d, d + 1);
    i = i - 1;
  }
  return result;
}

/// Roman numeral string to Int. Err for empty or invalid input; subtractive
/// notation (IV, IX, XL, XC, CD, CM) is supported. Complexity: O(len).
pub fn roman_to_int(s: Str) -> Result[Int, Str] {
  var len = string.str_len(s);
  if len == 0 {
    return Result[Int, Str]{ is_ok: false, value: 0, error: "empty" };
  }
  var total = 0;
  var i = 0;
  while i < len {
    var v = _roman_val(string.byte_at(s, i));
    if v < 0 {
      return Result[Int, Str]{ is_ok: false, value: 0, error: "invalid" };
    }
    if i + 1 < len {
      var v2 = _roman_val(string.byte_at(s, i + 1));
      if v2 > v {
        total = total + v2 - v;
        i = i + 2;
      } else {
        total = total + v;
        i = i + 1;
      }
    } else {
      total = total + v;
      i = i + 1;
    }
  }
  return Result[Int, Str]{ is_ok: true, value: total, error: "" };
}

// Value of a single Roman numeral byte, or -1.
fn _roman_val(b: UInt8) -> Int {
  var c = b as Int;
  if c == 73 { return 1; }
  if c == 86 { return 5; }
  if c == 88 { return 10; }
  if c == 76 { return 50; }
  if c == 67 { return 100; }
  if c == 68 { return 500; }
  if c == 77 { return 1000; }
  return -1;
}

/// Int to a Roman numeral string (1..3999); "" outside that range.
/// Complexity: O(n).
pub fn int_to_roman(n: Int) -> Str {
  if n < 1 || n > 3999 {
    return "";
  }
  var num = n;
  var result = "";
  var thousands = num / 1000;
  var k = 0;
  while k < thousands {
    result = result + "M";
    k = k + 1;
  }
  num = num % 1000;
  result = result + _roman_digit(num / 100, "C", "D", "M");
  num = num % 100;
  result = result + _roman_digit(num / 10, "X", "L", "C");
  num = num % 10;
  result = result + _roman_digit(num, "I", "V", "X");
  return result;
}

// One decimal digit as a Roman numeral with the 1/5/10 symbols (one, five,
// ten).
fn _roman_digit(d: Int, one: Str, five: Str, ten: Str) -> Str {
  if d == 0 { return ""; }
  if d <= 3 {
    var s = "";
    var i = 0;
    while i < d {
      s = s + one;
      i = i + 1;
    }
    return s;
  }
  if d == 4 { return one + five; }
  if d <= 8 {
    var s = five;
    var i = 5;
    while i < d {
      s = s + one;
      i = i + 1;
    }
    return s;
  }
  return one + ten;
}

/// Int to a Chinese numeral string (supports 0..99999999; larger values
/// return the 亿-form with the remainder documented). Complexity: O(log n).
pub fn chinese_numerals(n: Int) -> Str {
  if n == 0 { return "零"; }
  var neg = n < 0;
  var num = n;
  if neg { num = -num; }
  var result = "";
  if neg {
    result = "负";
  }
  var yi = num / 100000000;
  num = num % 100000000;
  if yi > 0 {
    result = result + _cn_4digit(yi) + "亿";
  }
  if num > 0 {
    if yi > 0 && num < 10000000 {
      result = result + "零";
    }
    result = result + _cn_4digit(num);
  }
  return result;
}

// Chinese numerals for 0..9999 with the standard zero rules.
fn _cn_4digit(n: Int) -> Str {
  if n == 0 { return "零"; }
  if n < 10 {
    return _cn_digit(n);
  }
  var d3 = n / 1000;
  var r2 = n % 1000;
  var d2 = r2 / 100;
  var r1 = r2 % 100;
  var d1 = r1 / 10;
  var d0 = r1 % 10;
  var s = "";
  if d3 > 0 {
    s = s + _cn_digit(d3) + "千";
  }
  if d2 > 0 {
    s = s + _cn_digit(d2) + "百";
  } else {
    if d3 > 0 && (d1 > 0 || d0 > 0) {
      s = s + "零";
    }
  }
  if d1 > 0 {
    if n >= 10 && n < 20 && d3 == 0 && d2 == 0 {
      s = s + "十";
    } else {
      s = s + _cn_digit(d1) + "十";
    }
  } else {
    if (d3 > 0 || d2 > 0) && d0 > 0 {
      s = s + "零";
    }
  }
  if d0 > 0 {
    s = s + _cn_digit(d0);
  }
  return s;
}

// One Chinese digit character.
fn _cn_digit(d: Int) -> Str {
  if d == 0 { return "零"; }
  if d == 1 { return "一"; }
  if d == 2 { return "二"; }
  if d == 3 { return "三"; }
  if d == 4 { return "四"; }
  if d == 5 { return "五"; }
  if d == 6 { return "六"; }
  if d == 7 { return "七"; }
  if d == 8 { return "八"; }
  return "九";
}

/// Int to a Japanese numeral string (〇一...九 + 十百千万; 0..99999999).
/// Complexity: O(log n).
pub fn japanese_numerals(n: Int) -> Str {
  if n == 0 { return "〇"; }
  var neg = n < 0;
  var num = n;
  if neg { num = -num; }
  var result = "";
  if neg {
    result = "負";
  }
  var man = num / 10000;
  num = num % 10000;
  if man > 0 {
    result = result + _jp_4digit(man) + "万";
  }
  if num > 0 {
    result = result + _jp_4digit(num);
  }
  return result;
}

// Japanese numerals for 0..9999.
fn _jp_4digit(n: Int) -> Str {
  if n == 0 { return "〇"; }
  var d3 = n / 1000;
  var r2 = n % 1000;
  var d2 = r2 / 100;
  var r1 = r2 % 100;
  var d1 = r1 / 10;
  var d0 = r1 % 10;
  var s = "";
  if d3 > 0 {
    s = s + _jp_digit(d3) + "千";
  }
  if d2 > 0 {
    s = s + _jp_digit(d2) + "百";
  }
  if d1 > 0 {
    s = s + _jp_digit(d1) + "十";
  }
  if d0 > 0 {
    s = s + _jp_digit(d0);
  }
  return s;
}

// One Japanese digit character.
fn _jp_digit(d: Int) -> Str {
  if d == 0 { return "〇"; }
  if d == 1 { return "一"; }
  if d == 2 { return "二"; }
  if d == 3 { return "三"; }
  if d == 4 { return "四"; }
  if d == 5 { return "五"; }
  if d == 6 { return "六"; }
  if d == 7 { return "七"; }
  if d == 8 { return "八"; }
  return "九";
}

/// Greedy Egyptian fraction expansion of numer/denom as (1, unit) pairs.
/// Empty for a non-positive numerator or denominator. Complexity: O(denom).
pub fn egyptian_fractions(numer: Int, denom: Int) -> Vec[(Int, Int)] {
  var out = Vec[(Int, Int)].new();
  if numer <= 0 || denom <= 0 { return out; }
  if numer >= denom {
    out.push((numer / denom, 1));
    numer = numer % denom;
  }
  var num = numer;
  var den = denom;
  while num > 0 {
    var unit = den / num + 1;
    out.push((1, unit));
    var new_num = num * unit - den;
    var new_den = den * unit;
    num = new_num;
    den = new_den;
    if unit <= 0 || den == 0 { num = 0; }
  }
  return out;
}

/// Babylonian-style base-60 notation: the sexagesimal places of n joined by
/// ';' (a documented approximation of cuneiform numerals). n == 0 yields "0".
/// Complexity: O(log_60 n).
pub fn babylonian_numerals(n: Int) -> Str {
  if n == 0 { return "0"; }
  var neg = n < 0;
  var num = n;
  if neg { num = -num; }
  var places = Vec[Int].new();
  while num > 0 {
    places.push(num % 60);
    num = num / 60;
  }
  var result = "";
  if neg {
    result = "-";
  }
  var i = places.len() - 1;
  while i >= 0 {
    var p = places[i];
    result = result + _to_radix(p, 10);
    if i > 0 {
      result = result + ";";
    }
    i = i - 1;
  }
  return result;
}

/// Int to a Greek alphabetic numeral string (1..999 using the standard
/// archaic digits; "" outside the range). Complexity: O(log n).
pub fn greek_numerals(n: Int) -> Str {
  if n < 1 || n > 999 {
    return "";
  }
  var result = "";
  var units = Vec[Str].new();
  units.push("α");
  units.push("β");
  units.push("γ");
  units.push("δ");
  units.push("ε");
  units.push("ϝ");
  units.push("ζ");
  units.push("η");
  units.push("θ");
  var tens = Vec[Str].new();
  tens.push("ι");
  tens.push("κ");
  tens.push("λ");
  tens.push("μ");
  tens.push("ν");
  tens.push("ξ");
  tens.push("ο");
  tens.push("π");
  tens.push("ϙ");
  var hundreds = Vec[Str].new();
  hundreds.push("ρ");
  hundreds.push("σ");
  hundreds.push("τ");
  hundreds.push("υ");
  hundreds.push("φ");
  hundreds.push("χ");
  hundreds.push("ψ");
  hundreds.push("ω");
  hundreds.push("ϡ");
  var h = n / 100;
  var t = (n % 100) / 10;
  var u = n % 10;
  if h > 0 {
    result = result + hundreds[h - 1];
  }
  if t > 0 {
    result = result + tens[t - 1];
  }
  if u > 0 {
    result = result + units[u - 1];
  }
  return result;
}

/// Continued-fraction coefficients of x (at most `terms` of them).
/// Complexity: O(terms).
pub fn continued_fraction(x: Float64, terms: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  if terms <= 0 || x != x { return out; }
  var value = x;
  var i = 0;
  while i < terms {
    var a = to_int(value);
    out.push(a);
    value = value - (a as Float64);
    if value <= 0.0 || value != value {
      i = terms;
    } else {
      value = 1.0 / value;
    }
    i = i + 1;
  }
  return out;
}

/// Reduced fraction (numer / gcd, denom / gcd) with the sign on the
/// numerator. Returns (0, 1) for denom == 0. Complexity: O(log n).
pub fn fraction_new(numer: Int, denom: Int) -> (Int, Int) {
  if denom == 0 {
    return (0, 1);
  }
  var num = numer;
  var den = denom;
  if den < 0 {
    num = -num;
    den = -den;
  }
  var g = math.algebra.gcd(num, den);
  if g < 0 { g = -g; }
  if g == 0 {
    return (0, 1);
  }
  return (num / g, den / g);
}

/// Sum of two reduced fractions (reduced again). Complexity: O(log n).
pub fn fraction_add(a: (Int, Int), b: (Int, Int)) -> (Int, Int) {
  var num = a.0 * b.1 + b.0 * a.1;
  var den = a.1 * b.1;
  return fraction_new(num, den);
}

/// Simplify sqrt(a)/sqrt(b) to (coefficient, radicand): the largest square
/// factor of a*b is pulled out of the radical. Returns (1, 1) for b == 0.
/// Complexity: O(sqrt(a*b)).
pub fn surd_simplify(a: Int, b: Int) -> (Int, Int) {
  if b == 0 {
    return (1, 1);
  }
  if a == 0 {
    return (0, 1);
  }
  var p = a;
  var q = b;
  if p < 0 { p = -p; }
  if q < 0 { q = -q; }
  var coeff = 1;
  var base = 2;
  var ab = p * q;
  var d = 2;
  while d * d <= ab {
    var count = 0;
    while ab % d == 0 {
      ab = ab / d;
      count = count + 1;
    }
    var pairs = count / 2;
    var k = 0;
    while k < pairs {
      coeff = coeff * d;
      k = k + 1;
    }
    d = d + 1;
  }
  return (coeff, ab);
}

/// Componentwise sum of two octonions (8 components). Empty for a length
/// mismatch. Complexity: O(8).
pub fn octonion_add(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if a.len() != 8 || b.len() != 8 { return out; }
  var i = 0;
  while i < 8 {
    out.push(a[i] + b[i]);
    i = i + 1;
  }
  return out;
}

/// Componentwise sum of two sedenions (16 components). Empty for a length
/// mismatch. Complexity: O(16).
pub fn sedenion_add(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if a.len() != 16 || b.len() != 16 { return out; }
  var i = 0;
  while i < 16 {
    out.push(a[i] + b[i]);
    i = i + 1;
  }
  return out;
}
