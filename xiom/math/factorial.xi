// XIOM - Math: Factorial
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.factorial

// Depends on: xiom.math

// ============================================================================
// Factorial variants, binomial/multinomial coefficients, and counting-number
// families (Stirling, Bell, Catalan, partitions). NOTE: current implementation
// lives in num/bigint.xi factorial/binomial + math/algebra.xi - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.math;

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

// True iff a * b overflows Int. Assumes both operands are finite Int values;
// the check is sign-aware (both negative products are positive).
fn _mul_ovf(a: Int, b: Int) -> Bool {
  if a == 0 || b == 0 { return false; }
  if a == 1 || b == 1 { return false; }
  if a > 0 && b > 0 { return a > 9223372036854775807 / b; }
  if a > 0 && b < 0 { return b < -9223372036854775808 / a; }
  if a < 0 && b > 0 { return a < -9223372036854775808 / b; }
  return a < 9223372036854775807 / b;
}

// True iff a + b overflows Int (sign-aware).
fn _add_ovf(a: Int, b: Int) -> Bool {
  if b > 0 && a > 9223372036854775807 - b { return true; }
  if b < 0 && a < -9223372036854775808 - b { return true; }
  return false;
}

// ---------------------------------------------------------------------------
// Factorial variants
// ---------------------------------------------------------------------------

// n! for n >= 0. Returns 0 for n < 0 (documented) and 0 (documented overflow)
// when the true value exceeds Int range (n > 20). Complexity: O(n).
/// n! for n >= 0. Returns 0 for n < 0 (documented) and 0 (documented overflow)
/// when the true value exceeds Int range (n > 20). Complexity: O(n).
pub fn factorial(n: Int) -> Int {
  if n < 0 { return 0; }
  if n <= 1 { return 1; }
  var result = 1;
  var i = 2;
  while i <= n {
    if result > 9223372036854775807 / i { return 0; }
    result = result * i;
    i = i + 1;
  }
  return result;
}

// Double factorial n!! = product of n, n-2, n-4, ... down to 1 (odd n) or 2
// (even n). Returns 0 for n < 0 and 0 (documented overflow) when the value
// exceeds Int range. Complexity: O(n/2).
/// Double factorial n!! = product of n, n-2, n-4, ... down to 1 (odd n) or 2
/// (even n). Returns 0 for n < 0 and 0 (documented overflow) when the value
/// exceeds Int range. Complexity: O(n/2).
pub fn double_factorial(n: Int) -> Int {
  if n < 0 { return 0; }
  if n <= 1 { return 1; }
  var result = 1;
  var i = n;
  while i > 1 {
    if result > 9223372036854775807 / i { return 0; }
    result = result * i;
    i = i - 2;
  }
  return result;
}

// Derangement count !n: the number of fixed-point-free permutations of n
// items. Uses the recurrence D(0)=1, D(1)=0, D(n) = (n-1)(D(n-1)+D(n-2)).
// Returns 0 for n < 0 and 0 (documented overflow) when D(n) exceeds Int
// range. Complexity: O(n).
/// Derangement count !n: the number of fixed-point-free permutations of n
/// items. Uses the recurrence D(0)=1, D(1)=0, D(n) = (n-1)(D(n-1)+D(n-2)).
/// Returns 0 for n < 0 and 0 (documented overflow) when D(n) exceeds Int
/// range. Complexity: O(n).
pub fn subfactorial(n: Int) -> Int {
  if n < 0 { return 0; }
  if n == 0 { return 1; }
  if n == 1 { return 0; }
  var a = 1;
  var b = 0;
  var i = 2;
  while i <= n {
    var s = a + b;
    if s < a { return 0; }
    var m = (i - 1) * s;
    if m < s { return 0; }
    a = b;
    b = m;
    i = i + 1;
  }
  return b;
}

// k-th multifactorial of n: product n, n-k, n-2k, ... down to the smallest
// positive term. Returns 0 for n < 0 or k <= 0 (documented) and 0
// (documented overflow) when the value exceeds Int range. Complexity: O(n/k).
/// k-th multifactorial of n: product n, n-k, n-2k, ... down to the smallest
/// positive term. Returns 0 for n < 0 or k <= 0 (documented) and 0
/// (documented overflow) when the value exceeds Int range. Complexity: O(n/k).
pub fn multifactorial(n: Int, k: Int) -> Int {
  if n < 0 { return 0; }
  if k <= 0 { return 0; }
  if n <= 1 { return 1; }
  var result = 1;
  var i = n;
  while i > 1 {
    if result > 9223372036854775807 / i { return 0; }
    result = result * i;
    i = i - k;
  }
  return result;
}

// ---------------------------------------------------------------------------
// Binomial / multinomial
// ---------------------------------------------------------------------------

// Binomial coefficient C(n, k). Returns 0 for invalid input (n < 0, k < 0,
// k > n) and 0 (documented overflow) when C(n, k) exceeds Int range. Uses the
// multiplicative form with a per-step overflow guard. Complexity: O(min(k,
// n - k)).
/// Binomial coefficient C(n, k). Returns 0 for invalid input (n < 0, k < 0,
/// k > n) and 0 (documented overflow) when C(n, k) exceeds Int range. Uses the
/// multiplicative form with a per-step overflow guard. Complexity: O(min(k,
/// n - k)).
pub fn binomial(n: Int, k: Int) -> Int {
  if n < 0 { return 0; }
  if k < 0 || k > n { return 0; }
  if k == 0 || k == n { return 1; }
  var kk = k;
  if kk > n - kk { kk = n - kk; }
  var result = 1;
  var i = 1;
  while i <= kk {
    var num = n - i + 1;
    if result > 9223372036854775807 / num { return 0; }
    result = result * num;
    result = result / i;
    i = i + 1;
  }
  return result;
}

// Alias of binomial. Complexity: O(min(k, n - k)).
/// Alias of binomial. Complexity: O(min(k, n - k)).
pub fn binomial_coeff(n: Int, k: Int) -> Int {
  return binomial(n, k);
}

// Multinomial coefficient n!/(k1! k2! ... km!) where the ki sum to n.
// Returns 0 when the entries are negative or do not sum to n, and 0
// (documented overflow) when the value exceeds Int range. Computed as a chain
// of binomial coefficients. Complexity: O(m * min(k_i, ...)).
/// Multinomial coefficient n!/(k1! k2! ... km!) where the ki sum to n.
/// Returns 0 when the entries are negative or do not sum to n, and 0
/// (documented overflow) when the value exceeds Int range. Computed as a chain
/// of binomial coefficients. Complexity: O(m * min(k_i, ...)).
pub fn multinomial(n: Int, ks: &Vec[Int]) -> Int {
  if n < 0 { return 0; }
  var total = 0;
  var i = 0;
  while i < ks.len() {
    if ks[i] < 0 { return 0; }
    total = total + ks[i];
    i = i + 1;
  }
  if total != n { return 0; }
  var result = 1;
  var remaining = n;
  var j = 0;
  while j < ks.len() {
    var c = binomial(remaining, ks[j]);
    if c == 0 { return 0; }
    if _mul_ovf(result, c) { return 0; }
    result = result * c;
    remaining = remaining - ks[j];
    j = j + 1;
  }
  return result;
}

// Falling factorial x * (x-1) * ... * (x-k+1). Returns 0 for k < 0 and 0
// (documented overflow) when the magnitude exceeds Int range. k == 0 gives 1.
// Complexity: O(k).
/// Falling factorial x * (x-1) * ... * (x-k+1). Returns 0 for k < 0 and 0
/// (documented overflow) when the magnitude exceeds Int range. k == 0 gives 1.
/// Complexity: O(k).
pub fn falling_factorial(x: Int, k: Int) -> Int {
  if k < 0 { return 0; }
  if k == 0 { return 1; }
  var result = 1;
  var i = 0;
  while i < k {
    var term = x - i;
    if term > 0 {
      if result > 9223372036854775807 / term { return 0; }
    }
    if term < 0 {
      var m = -term;
      if result > 9223372036854775807 / m { return 0; }
    }
    result = result * term;
    i = i + 1;
  }
  return result;
}

// Rising factorial x * (x+1) * ... * (x+k-1). Returns 0 for k < 0 and 0
// (documented overflow) when the magnitude exceeds Int range. k == 0 gives 1.
// Complexity: O(k).
/// Rising factorial x * (x+1) * ... * (x+k-1). Returns 0 for k < 0 and 0
/// (documented overflow) when the magnitude exceeds Int range. k == 0 gives 1.
/// Complexity: O(k).
pub fn rising_factorial(x: Int, k: Int) -> Int {
  if k < 0 { return 0; }
  if k == 0 { return 1; }
  var result = 1;
  var i = 0;
  while i < k {
    var term = x + i;
    if term > 0 {
      if result > 9223372036854775807 / term { return 0; }
    }
    if term < 0 {
      var m = -term;
      if result > 9223372036854775807 / m { return 0; }
    }
    result = result * term;
    i = i + 1;
  }
  return result;
}

// ---------------------------------------------------------------------------
// Counting-number families
// ---------------------------------------------------------------------------

// Unsigned Stirling number of the first kind s(n, k): permutations of n items
// with exactly k cycles. Row DP over s(n,k) = s(n-1,k-1) + (n-1)*s(n-1,k) with
// s(0,0) = 1. Returns 0 for invalid input (n < 0, k < 0, k > n) and 0
// (documented overflow) when the value exceeds Int range. Complexity: O(n*k).
/// Unsigned Stirling number of the first kind s(n, k): permutations of n items
/// with exactly k cycles. Row DP over s(n,k) = s(n-1,k-1) + (n-1)*s(n-1,k) with
/// s(0,0) = 1. Returns 0 for invalid input (n < 0, k < 0, k > n) and 0
/// (documented overflow) when the value exceeds Int range. Complexity: O(n*k).
pub fn stirling_first(n: Int, k: Int) -> Int {
  if n < 0 || k < 0 || k > n { return 0; }
  if n == 0 { return 1; }
  var row = Vec[Int].new();
  row.push(1);
  var i = 1;
  while i <= n {
    var next = Vec[Int].new();
    var j = 0;
    while j <= i {
      if j == 0 {
        next.push(0);
      } else {
        if j == i {
          next.push(1);
        } else {
          var left = row[j - 1];
          var m = (i - 1) * row[j];
          if _mul_ovf(i - 1, row[j]) { return 0; }
          if _add_ovf(left, m) { return 0; }
          next.push(left + m);
        }
      }
      j = j + 1;
    }
    row = next;
    i = i + 1;
  }
  return row[k];
}

// Stirling number of the second kind S(n, k): partitions of an n-element set
// into k nonempty blocks. Row DP over S(n,k) = k*S(n-1,k) + S(n-1,k-1) with
// S(0,0) = 1. Returns 0 for invalid input and 0 (documented overflow) when the
// value exceeds Int range. Complexity: O(n*k).
/// Stirling number of the second kind S(n, k): partitions of an n-element set
/// into k nonempty blocks. Row DP over S(n,k) = k*S(n-1,k) + S(n-1,k-1) with
/// S(0,0) = 1. Returns 0 for invalid input and 0 (documented overflow) when the
/// value exceeds Int range. Complexity: O(n*k).
pub fn stirling_second(n: Int, k: Int) -> Int {
  if n < 0 || k < 0 || k > n { return 0; }
  if n == 0 { return 1; }
  var row = Vec[Int].new();
  row.push(1);
  var i = 1;
  while i <= n {
    var next = Vec[Int].new();
    var j = 0;
    while j <= i {
      if j == 0 {
        next.push(0);
      } else {
        if j == i {
          next.push(1);
        } else {
          var m = j * row[j];
          if _mul_ovf(j, row[j]) { return 0; }
          if _add_ovf(row[j - 1], m) { return 0; }
          next.push(row[j - 1] + m);
        }
      }
      j = j + 1;
    }
    row = next;
    i = i + 1;
  }
  return row[k];
}

// Bell number B(n): the number of partitions of an n-element set. Computed
// via the Aitken / Bell triangle, whose rightmost entry of row k is B(k+1)
// (row 0 is [1] and B(0) = B(1) = 1), so the value is the last entry of row
// n - 1. Returns 0 for n < 0 and 0 (documented overflow) when B(n) exceeds
// Int range. Complexity: O(n^2).
/// Bell number B(n): the number of partitions of an n-element set. Computed
/// via the Aitken / Bell triangle, whose rightmost entry of row k is B(k+1)
/// (row 0 is [1] and B(0) = B(1) = 1), so the value is the last entry of row
/// n - 1. Returns 0 for n < 0 and 0 (documented overflow) when B(n) exceeds
/// Int range. Complexity: O(n^2).
pub fn bell(n: Int) -> Int {
  if n < 0 { return 0; }
  if n == 0 { return 1; }
  var row = Vec[Int].new();
  row.push(1);
  var i = 1;
  while i <= n - 1 {
    var next = Vec[Int].new();
    next.push(row[row.len() - 1]);
    var j = 1;
    while j <= i {
      if _add_ovf(next[j - 1], row[j - 1]) { return 0; }
      next.push(next[j - 1] + row[j - 1]);
      j = j + 1;
    }
    row = next;
    i = i + 1;
  }
  return row[row.len() - 1];
}

// Catalan number C_n = C(2n, n)/(n+1). Returns 0 for n < 0 and 0 (documented
// overflow) when the value exceeds Int range (n > 33). Complexity: O(n).
/// Catalan number C_n = C(2n, n)/(n+1). Returns 0 for n < 0 and 0 (documented
/// overflow) when the value exceeds Int range (n > 33). Complexity: O(n).
pub fn catalan(n: Int) -> Int {
  if n < 0 { return 0; }
  if n == 0 { return 1; }
  var b = binomial(2 * n, n);
  if b == 0 { return 0; }
  return b / (n + 1);
}

// Eulerian number A(n, k): permutations of n items with exactly k ascents.
// Row DP over A(n,k) = (n-k)*A(n-1,k-1) + (k+1)*A(n-1,k) with A(0,0) = 1 and
// A(n,n) = 0. Returns 0 for invalid input and 0 (documented overflow) when the
// value exceeds Int range. Complexity: O(n*k).
/// Eulerian number A(n, k): permutations of n items with exactly k ascents.
/// Row DP over A(n,k) = (n-k)*A(n-1,k-1) + (k+1)*A(n-1,k) with A(0,0) = 1 and
/// A(n,n) = 0. Returns 0 for invalid input and 0 (documented overflow) when the
/// value exceeds Int range. Complexity: O(n*k).
pub fn eulerian(n: Int, k: Int) -> Int {
  if n < 0 || k < 0 || k > n { return 0; }
  if n == 0 { return 1; }
  var prev = Vec[Int].new();
  prev.push(1);
  var i = 1;
  while i <= n {
    var next = Vec[Int].new();
    var j = 0;
    while j <= i {
      if j == 0 {
        next.push(1);
      } else {
        if j == i {
          next.push(0);
        } else {
          var t1 = i - j;
          var m1 = t1 * prev[j - 1];
          if _mul_ovf(t1, prev[j - 1]) { return 0; }
          var t2 = j + 1;
          var m2 = t2 * prev[j];
          if _mul_ovf(t2, prev[j]) { return 0; }
          if _add_ovf(m1, m2) { return 0; }
          next.push(m1 + m2);
        }
      }
      j = j + 1;
    }
    prev = next;
    i = i + 1;
  }
  return prev[k];
}

// Narayana number N(n, k) = C(n, k) * C(n, k-1) / n. Returns 0 for invalid
// input (n <= 0, k <= 0, k > n) and 0 (documented overflow) when the value
// exceeds Int range. Complexity: O(min(k, n-k)).
/// Narayana number N(n, k) = C(n, k) * C(n, k-1) / n. Returns 0 for invalid
/// input (n <= 0, k <= 0, k > n) and 0 (documented overflow) when the value
/// exceeds Int range. Complexity: O(min(k, n-k)).
pub fn narayana(n: Int, k: Int) -> Int {
  if n <= 0 || k <= 0 || k > n { return 0; }
  if k == 1 { return 1; }
  var a = binomial(n, k);
  var b = binomial(n, k - 1);
  if a == 0 || b == 0 { return 0; }
  if _mul_ovf(a, b) { return 0; }
  return (a * b) / n;
}

// Lah number L(n, k) = C(n, k) * C(n-1, k-1) * (n-k)!. Returns 0 for invalid
// input (n <= 0, k <= 0, k > n) and 0 (documented overflow) when the value
// exceeds Int range. Complexity: O(min(k, n-k) + (n-k)).
/// Lah number L(n, k) = C(n, k) * C(n-1, k-1) * (n-k)!. Returns 0 for invalid
/// input (n <= 0, k <= 0, k > n) and 0 (documented overflow) when the value
/// exceeds Int range. Complexity: O(min(k, n-k) + (n-k)).
pub fn lah(n: Int, k: Int) -> Int {
  if n <= 0 || k <= 0 || k > n { return 0; }
  if k == n { return 1; }
  if k == 1 { return factorial(n); }
  var a = binomial(n, k);
  var b = binomial(n - 1, k - 1);
  var f = factorial(n - k);
  if a == 0 || b == 0 || f == 0 { return 0; }
  if _mul_ovf(a, b) { return 0; }
  var p = a * b;
  if _mul_ovf(p, f) { return 0; }
  return p * f;
}

// Motzkin number M_n (lattice paths / non-crossing partitions). Uses the
// closed recurrence M(n) = ((2n+1)M(n-1) + (3n-3)M(n-2))/(n+2), M(0) = M(1) = 1.
// Returns 0 for n < 0 and 0 (documented overflow) when M_n exceeds Int range.
// Complexity: O(n).
/// Motzkin number M_n (lattice paths / non-crossing partitions). Uses the
/// closed recurrence M(n) = ((2n+1)M(n-1) + (3n-3)M(n-2))/(n+2), M(0) = M(1) = 1.
/// Returns 0 for n < 0 and 0 (documented overflow) when M_n exceeds Int range.
/// Complexity: O(n).
pub fn motzkin(n: Int) -> Int {
  if n < 0 { return 0; }
  if n == 0 { return 1; }
  if n == 1 { return 1; }
  var prev2 = 1;
  var prev1 = 1;
  var i = 2;
  while i <= n {
    var t1 = (2 * i + 1) * prev1;
    if _mul_ovf(2 * i + 1, prev1) { return 0; }
    var t2 = (3 * i - 3) * prev2;
    if _mul_ovf(3 * i - 3, prev2) { return 0; }
    if _add_ovf(t1, t2) { return 0; }
    var m = (t1 + t2) / (i + 2);
    prev2 = prev1;
    prev1 = m;
    i = i + 1;
  }
  return prev1;
}

// Large Schroder number S_n. Uses S(n) = S(n-1) + sum_{k=0..n-1} S(k)*S(n-1-k),
// S(0) = 1. Returns 0 for n < 0 and 0 (documented overflow) when S_n exceeds
// Int range. Complexity: O(n^2).
/// Large Schroder number S_n. Uses S(n) = S(n-1) + sum_{k=0..n-1} S(k)*S(n-1-k),
/// S(0) = 1. Returns 0 for n < 0 and 0 (documented overflow) when S_n exceeds
/// Int range. Complexity: O(n^2).
pub fn schroeder(n: Int) -> Int {
  if n < 0 { return 0; }
  if n == 0 { return 1; }
  var arr = Vec[Int].new();
  arr.push(1);
  var i = 1;
  while i <= n {
    var total = arr[i - 1];
    var k = 0;
    while k < i {
      var p = arr[k] * arr[i - 1 - k];
      if _mul_ovf(arr[k], arr[i - 1 - k]) { return 0; }
      if _add_ovf(total, p) { return 0; }
      total = total + p;
      k = k + 1;
    }
    arr.push(total);
    i = i + 1;
  }
  return arr[n];
}

// Number of integer partitions p(n). Uses the Euler pentagonal-number
// recurrence p(n) = sum_{k != 0} (-1)^(k+1) p(n - k(3k-1)/2). Returns 0 for
// n < 0 and 0 (documented overflow) when p(n) exceeds Int range (n > 255).
// Complexity: O(n * sqrt(n)).
/// Number of integer partitions p(n). Uses the Euler pentagonal-number
/// recurrence p(n) = sum_{k != 0} (-1)^(k+1) p(n - k(3k-1)/2). Returns 0 for
/// n < 0 and 0 (documented overflow) when p(n) exceeds Int range (n > 255).
/// Complexity: O(n * sqrt(n)).
pub fn partition_count(n: Int) -> Int {
  if n < 0 { return 0; }
  if n == 0 { return 1; }
  var p = Vec[Int].new();
  p.push(1);
  var i = 1;
  while i <= n {
    var total = 0;
    var k = 1;
    var sign = 1;
    var pent = k * (3 * k - 1) / 2;
    while pent <= i {
      if sign == 1 {
        if _add_ovf(total, p[i - pent]) { return 0; }
        total = total + p[i - pent];
      } else {
        if _add_ovf(total, -(p[i - pent])) { return 0; }
        total = total - p[i - pent];
      }
      var pent2 = k * (3 * k + 1) / 2;
      if pent2 <= i {
        if sign == 1 {
          if _add_ovf(total, p[i - pent2]) { return 0; }
          total = total + p[i - pent2];
        } else {
          if _add_ovf(total, -(p[i - pent2])) { return 0; }
          total = total - p[i - pent2];
        }
      }
      k = k + 1;
      sign = -sign;
      pent = k * (3 * k - 1) / 2;
    }
    p.push(total);
    i = i + 1;
  }
  return p[n];
}

// All integer partitions of n as lists (each partition non-increasing,
// starting from the largest part; the result order is unspecified). Returns an
// empty list for n < 0; n == 0 yields a single empty partition. Complexity:
// O(p(n) * n).
/// All integer partitions of n as lists (each partition non-increasing,
/// starting from the largest part; the result order is unspecified). Returns an
/// empty list for n < 0; n == 0 yields a single empty partition. Complexity:
/// O(p(n) * n).
pub fn integer_partitions(n: Int) -> Vec[Vec[Int]] {
  var out = Vec[Vec[Int]].new();
  if n < 0 { return out; }
  if n == 0 {
    var empty = Vec[Int].new();
    out.push(empty);
    return out;
  }
  var cur = Vec[Int].new();
  _parts_rec(n, n, &cur, &out);
  return out;
}

// Recursive partition enumeration: fills cur with parts <= max_part summing to
// rem; appends a copy of cur to out whenever rem hits 0.
fn _parts_rec(rem: Int, max_part: Int, cur: &mut Vec[Int], out: &mut Vec[Vec[Int]]) {
  if rem == 0 {
    out.push(_copy_vec(cur));
    return;
  }
  var first = max_part;
  if rem < first { first = rem; }
  var p = first;
  while p >= 1 {
    cur.push(p);
    _parts_rec(rem - p, p, cur, out);
    cur.pop();
    p = p - 1;
  }
}

// Independent copy of a Vec[Int] (defensive: enumeration helpers push copies
// so later mutation of the working vector cannot alias the pushed results).
fn _copy_vec(v: &mut Vec[Int]) -> Vec[Int] {
  var c = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    c.push(v[i]);
    i = i + 1;
  }
  return c;
}

// Number of derangements of n items (fixed-point-free permutations). Alias of
// subfactorial. Returns 0 for n < 0 and 0 (documented overflow). Complexity:
// O(n).
/// Number of derangements of n items (fixed-point-free permutations). Alias of
/// subfactorial. Returns 0 for n < 0 and 0 (documented overflow). Complexity:
/// O(n).
pub fn derangements(n: Int) -> Int {
  return subfactorial(n);
}

// Bell triangle rows up to n: rows 0..n inclusive. Row 0 is [1]; each later
// row starts with the previous row's last entry and continues with the sum of
// the entry to its left and the one above-left, so the rightmost entry of row
// k is B(k+1) and the leftmost is B(k). Returns an empty list for n < 0. Cells
// that would overflow Int are stored as 0 (documented). Complexity: O(n^2).
/// Bell triangle rows up to n: rows 0..n inclusive. Row 0 is [1]; each later
/// row starts with the previous row's last entry and continues with the sum of
/// the entry to its left and the one above-left, so the rightmost entry of row
/// k is B(k+1) and the leftmost is B(k). Returns an empty list for n < 0. Cells
/// that would overflow Int are stored as 0 (documented). Complexity: O(n^2).
pub fn bell_triangle(n: Int) -> Vec[Vec[Int]] {
  var out = Vec[Vec[Int]].new();
  if n < 0 { return out; }
  var row = Vec[Int].new();
  row.push(1);
  out.push(row);
  var i = 1;
  while i <= n {
    var next = Vec[Int].new();
    next.push(row[row.len() - 1]);
    var j = 1;
    while j <= i {
      var v = next[j - 1] + row[j - 1];
      if v < next[j - 1] { v = 0; }
      next.push(v);
      j = j + 1;
    }
    row = next;
    out.push(row);
    i = i + 1;
  }
  return out;
}
