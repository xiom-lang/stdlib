// XIOM - Math: Combinatorics
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.combinatorics

// Depends on: xiom.math

// ============================================================================
// Counting functions and enumeration of permutations, combinations, partitions,
// and number-theoretic sequences. NOTE: current implementation lives in
// math/algebra.xi + num/bigint.xi + math/series.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.math;

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

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

// All permutations of elems: choose each element in turn, recurse on the rest.
fn _perm_rec(elems: &Vec[Int], cur: &mut Vec[Int], out: &mut Vec[Vec[Int]]) {
  if elems.len() == 0 {
    out.push(_copy_vec(cur));
    return;
  }
  var i = 0;
  while i < elems.len() {
    var next = Vec[Int].new();
    var j = 0;
    while j < elems.len() {
      if j != i { next.push(elems[j]); }
      j = j + 1;
    }
    cur.push(elems[i]);
    _perm_rec(&next, cur, out);
    cur.pop();
    i = i + 1;
  }
}

// All fixed-point-free permutations of 1..n: like _perm_rec but the value that
// would land at its own position (cur.len() + 1) is skipped.
fn _derange_rec(elems: &Vec[Int], cur: &mut Vec[Int], out: &mut Vec[Vec[Int]]) {
  if elems.len() == 0 {
    out.push(_copy_vec(cur));
    return;
  }
  var i = 0;
  while i < elems.len() {
    var pos = cur.len() + 1;
    if elems[i] != pos {
      var next = Vec[Int].new();
      var j = 0;
      while j < elems.len() {
        if j != i { next.push(elems[j]); }
        j = j + 1;
      }
      cur.push(elems[i]);
      _derange_rec(&next, cur, out);
      cur.pop();
    }
    i = i + 1;
  }
}

// All k-combinations of elems starting the pick at index start.
fn _comb_rec(elems: &Vec[Int], k: Int, start: Int, cur: &mut Vec[Int], out: &mut Vec[Vec[Int]]) {
  if cur.len() == k {
    out.push(_copy_vec(cur));
    return;
  }
  var i = start;
  while i < elems.len() {
    cur.push(elems[i]);
    _comb_rec(elems, k, i + 1, cur, out);
    cur.pop();
    i = i + 1;
  }
}

// ---------------------------------------------------------------------------
// Basic counting
// ---------------------------------------------------------------------------

/// Number of k-permutations of n distinct items: n!/(n-k)!. Delegates to
/// xiom.math.factorial.falling_factorial (returns 0 for invalid input and on
/// overflow). Complexity: O(k).
pub fn permutations(n: Int, k: Int) -> Int {
  return math.factorial.falling_factorial(n, k);
}

/// Number of k-combinations of n distinct items: C(n, k). Delegates to
/// xiom.math.factorial.binomial. Complexity: O(min(k, n-k)).
pub fn combinations(n: Int, k: Int) -> Int {
  return math.factorial.binomial(n, k);
}

/// Number of ordered k-selections from n items with repetition: n^k. Returns 0
/// for n < 0 or k < 0 (documented), 1 for k == 0, and 0 (documented overflow)
/// when n^k exceeds Int range. Complexity: O(k).
pub fn permutations_with_repetition(n: Int, k: Int) -> Int {
  if n < 0 || k < 0 { return 0; }
  if k == 0 { return 1; }
  if n == 0 { return 0; }
  var result = 1;
  var i = 0;
  while i < k {
    if result > 9223372036854775807 / n { return 0; }
    result = result * n;
    i = i + 1;
  }
  return result;
}

/// Number of unordered k-selections from n items with repetition:
/// C(n + k - 1, k). Returns 0 for n < 0 or k < 0 and on overflow (documented).
/// Complexity: O(min(k, n-1)).
pub fn combinations_with_repetition(n: Int, k: Int) -> Int {
  if n < 0 || k < 0 { return 0; }
  if n == 0 {
    if k == 0 { return 1; }
    return 0;
  }
  if k == 0 { return 1; }
  var m = n + k - 1;
  if m < n { return 0; }
  return math.factorial.binomial(m, k);
}

/// Number of derangements of n items (fixed-point-free permutations). Delegates
/// to xiom.math.factorial.subfactorial. Complexity: O(n).
pub fn derangements(n: Int) -> Int {
  return math.factorial.subfactorial(n);
}

/// Bell number B(n): partitions of an n-set. Delegates to
/// xiom.math.factorial.bell. Complexity: O(n^2).
pub fn bell_numbers(n: Int) -> Int {
  return math.factorial.bell(n);
}

/// Catalan number C_n. Delegates to xiom.math.factorial.catalan. Complexity:
/// O(n).
pub fn catalan_numbers(n: Int) -> Int {
  return math.factorial.catalan(n);
}

/// Eulerian number A(n, k): permutations of n items with exactly k ascents.
/// Delegates to xiom.math.factorial.eulerian. Complexity: O(n*k).
pub fn eulerian_numbers(n: Int, k: Int) -> Int {
  return math.factorial.eulerian(n, k);
}

/// Signed Stirling numbers of the first kind s(n, k). Derived from the unsigned
/// numbers: s(n,k) = (-1)^(n-k) * |s(n,k)|. Delegates to
/// xiom.math.factorial.stirling_first. Complexity: O(n*k).
pub fn stirling_numbers_1(n: Int, k: Int) -> Int {
  var s = math.factorial.stirling_first(n, k);
  if (n - k) % 2 == 1 { return -s; }
  return s;
}

/// Stirling numbers of the second kind S(n, k): partitions of an n-set into k
/// blocks. Delegates to xiom.math.factorial.stirling_second. Complexity:
/// O(n*k).
pub fn stirling_numbers_2(n: Int, k: Int) -> Int {
  return math.factorial.stirling_second(n, k);
}

/// Lah numbers L(n, k). Delegates to xiom.math.factorial.lah. Complexity:
/// O(min(k, n-k) + (n-k)).
pub fn lah_numbers(n: Int, k: Int) -> Int {
  return math.factorial.lah(n, k);
}

/// Narayana numbers N(n, k). Delegates to xiom.math.factorial.narayana.
/// Complexity: O(min(k, n-k)).
pub fn narayana_numbers(n: Int, k: Int) -> Int {
  return math.factorial.narayana(n, k);
}

// ---------------------------------------------------------------------------
// Sequences
// ---------------------------------------------------------------------------

/// Fibonacci number F(n), 0-indexed: F(0) = 0, F(1) = 1. Returns 0 for n < 0
/// and 0 (documented overflow) when F(n) exceeds Int range (n > 92).
/// Complexity: O(n).
pub fn fibonacci(n: Int) -> Int {
  if n < 0 { return 0; }
  if n <= 1 { return n; }
  var a = 0;
  var b = 1;
  var i = 2;
  while i <= n {
    if b > 9223372036854775807 - a { return 0; }
    var c = a + b;
    a = b;
    b = c;
    i = i + 1;
  }
  return b;
}

/// Term n of the Fibonacci-like sequence beginning with a and b (term 0 is a,
/// term 1 is b, each later term is the sum of the previous two). Returns 0 for
/// n < 0 and 0 (documented overflow) when the term exceeds Int range.
/// Complexity: O(n).
pub fn fibonacci_start(a: Int, b: Int, n: Int) -> Int {
  if n < 0 { return 0; }
  if n == 0 { return a; }
  var t0 = a;
  var t1 = b;
  if n == 1 { return t1; }
  var i = 2;
  while i <= n {
    if t1 > 0 && t0 > 9223372036854775807 - t1 { return 0; }
    if t1 < 0 && t0 < -9223372036854775808 - t1 { return 0; }
    var c = t0 + t1;
    t0 = t1;
    t1 = c;
    i = i + 1;
  }
  return t1;
}

/// Lucas number L(n): L(0) = 2, L(1) = 1, L(n) = L(n-1) + L(n-2). Returns 0
/// for n < 0 and 0 (documented overflow) when L(n) exceeds Int range.
/// Complexity: O(n).
pub fn lucas(n: Int) -> Int {
  if n < 0 { return 0; }
  if n == 0 { return 2; }
  if n == 1 { return 1; }
  var a = 2;
  var b = 1;
  var i = 2;
  while i <= n {
    if b > 9223372036854775807 - a { return 0; }
    var c = a + b;
    a = b;
    b = c;
    i = i + 1;
  }
  return b;
}

/// Tribonacci number T(n): T(0) = T(1) = 0, T(2) = 1,
/// T(n) = T(n-1) + T(n-2) + T(n-3). Returns 0 for n < 0 and 0 (documented
/// overflow) when T(n) exceeds Int range. Complexity: O(n).
pub fn tribonacci(n: Int) -> Int {
  if n < 0 { return 0; }
  if n < 2 { return 0; }
  if n == 2 { return 1; }
  var a = 0;
  var b = 0;
  var c = 1;
  var i = 3;
  while i <= n {
    var s = a + b;
    if s < a { return 0; }
    if c > 9223372036854775807 - s { return 0; }
    var t = s + c;
    a = b;
    b = c;
    c = t;
    i = i + 1;
  }
  return c;
}

/// Tetranacci number T(n): T(0) = T(1) = T(2) = 0, T(3) = 1, and each later
/// term is the sum of the previous four. Returns 0 for n < 0 and 0 (documented
/// overflow) when T(n) exceeds Int range. Complexity: O(n).
pub fn tetranacci(n: Int) -> Int {
  if n < 0 { return 0; }
  if n < 3 { return 0; }
  if n == 3 { return 1; }
  var a = 0;
  var b = 0;
  var c = 0;
  var d = 1;
  var i = 4;
  while i <= n {
    var s1 = a + b;
    if s1 < a { return 0; }
    var s2 = c + d;
    if s2 < c { return 0; }
    if s2 > 9223372036854775807 - s1 { return 0; }
    var t = s1 + s2;
    a = b;
    b = c;
    c = d;
    d = t;
    i = i + 1;
  }
  return d;
}

/// Number of integer partitions p(n). Delegates to
/// xiom.math.factorial.partition_count. Complexity: O(n * sqrt(n)).
pub fn partitions(n: Int) -> Int {
  return math.factorial.partition_count(n);
}

/// All integer partitions of n as lists. Delegates to
/// xiom.math.factorial.integer_partitions. Complexity: O(p(n) * n).
pub fn integer_partitions(n: Int) -> Vec[Vec[Int]] {
  return math.factorial.integer_partitions(n);
}

/// Number of compositions of n into exactly k positive parts: C(n-1, k-1).
/// Returns 0 for n < 0, k <= 0, and k > n; n == 0, k == 0 yields 1 (the empty
/// composition) and n == 0 with k > 0 yields 0. Complexity: O(min(k, n-k)).
pub fn compositions(n: Int, k: Int) -> Int {
  if n < 0 { return 0; }
  if n == 0 {
    if k == 0 { return 1; }
    return 0;
  }
  if k <= 0 { return 0; }
  if k > n { return 0; }
  return math.factorial.binomial(n - 1, k - 1);
}

/// Total number of compositions of n: 2^(n-1) for n >= 1, 1 for n == 0.
/// Returns 0 for n < 0 and 0 (documented overflow) when 2^(n-1) exceeds Int
/// range (n > 63). Complexity: O(n).
pub fn compositions_all(n: Int) -> Int {
  if n < 0 { return 0; }
  if n == 0 { return 1; }
  var result = 1;
  var i = 1;
  while i < n {
    if result > 9223372036854775807 / 2 { return 0; }
    result = result * 2;
    i = i + 1;
  }
  return result;
}

/// Number of onto (surjective) functions from an n-set to a k-set:
/// k! * S(n, k). Returns 0 for n < 0, k < 0, k > n, and 0 (documented
/// overflow) when the count exceeds Int range. Complexity: O(n*k + k).
pub fn surjections(n: Int, k: Int) -> Int {
  if n < 0 || k < 0 { return 0; }
  if k > n { return 0; }
  var s = math.factorial.stirling_second(n, k);
  var f = math.factorial.factorial(k);
  if s == 0 { return 0; }
  if f == 0 { return 0; }
  if s > 9223372036854775807 / f { return 0; }
  return s * f;
}

/// Number of involutions on n elements (self-inverse permutations). Uses the
/// recurrence I(n) = I(n-1) + (n-1)*I(n-2), I(0) = I(1) = 1. Returns 0 for
/// n < 0 and 0 (documented overflow) when I(n) exceeds Int range.
/// Complexity: O(n).
pub fn involutions(n: Int) -> Int {
  if n < 0 { return 0; }
  if n <= 1 { return 1; }
  var a = 1;
  var b = 1;
  var i = 2;
  while i <= n {
    var m = (i - 1) * a;
    if m < a { return 0; }
    if b > 9223372036854775807 - m { return 0; }
    var c = b + m;
    a = b;
    b = c;
    i = i + 1;
  }
  return b;
}

// ---------------------------------------------------------------------------
// Enumeration
// ---------------------------------------------------------------------------

/// All fixed-point-free permutations of 1..n as lists. Returns the empty list
/// for n < 0; n == 0 yields a single empty permutation. Complexity: O(!n * n).
pub fn derangements_enum(n: Int) -> Vec[Vec[Int]] {
  var out = Vec[Vec[Int]].new();
  if n < 0 { return out; }
  if n == 0 {
    var empty = Vec[Int].new();
    out.push(empty);
    return out;
  }
  var elems = Vec[Int].new();
  var i = 1;
  while i <= n {
    elems.push(i);
    i = i + 1;
  }
  var cur = Vec[Int].new();
  _derange_rec(&elems, &cur, &out);
  return out;
}
/// All permutations of elems as lists (n! results). Returns an empty list for
/// an empty input. Complexity: O(n! * n).
pub fn permutations_enum(elems: &Vec[Int]) -> Vec[Vec[Int]] {
  var out = Vec[Vec[Int]].new();
  var cur = Vec[Int].new();
  _perm_rec(elems, &cur, &out);
  return out;
}

/// All k-combinations of elems as lists (C(n, k) results). Returns an empty
/// list for k < 0 or k > n. Complexity: O(C(n, k) * k).
pub fn combinations_enum(elems: &Vec[Int], k: Int) -> Vec[Vec[Int]] {
  var out = Vec[Vec[Int]].new();
  if k < 0 || k > elems.len() { return out; }
  var cur = Vec[Int].new();
  _comb_rec(elems, k, 0, &cur, &out);
  return out;
}

/// All k-element subsets of elems as lists. Alias of combinations_enum.
/// Complexity: O(C(n, k) * k).
pub fn subsets_enum(elems: &Vec[Int], k: Int) -> Vec[Vec[Int]] {
  return combinations_enum(elems, k);
}

/// All subsets of elems as lists (2^n results). Returns an empty list when
/// n > 20 (documented guard against an impractical 2^n result set).
/// Complexity: O(2^n * n).
pub fn powerset_enum(elems: &Vec[Int]) -> Vec[Vec[Int]] {
  var out = Vec[Vec[Int]].new();
  var n = elems.len();
  if n > 20 { return out; }
  var total = 1;
  var t = 0;
  while t < n {
    total = total * 2;
    t = t + 1;
  }
  var mask = 0;
  while mask < total {
    var sub = Vec[Int].new();
    var b = 0;
    var bitval = 1;
    while b < n {
      if math.bit_and(mask, bitval) != 0 { sub.push(elems[b]); }
      bitval = bitval * 2;
      b = b + 1;
    }
    out.push(sub);
    mask = mask + 1;
  }
  return out;
}
