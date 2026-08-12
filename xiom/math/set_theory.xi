// XIOM - Math: Set Theory
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.set_theory

// Depends on: none

// ============================================================================
// Set type and elementary set-theoretic operations on hash-set collections.
// TODO(compiler): implement.
// ============================================================================

// The API models a set as an unordered Vec[Int] of unique elements; every
// function tolerates duplicate entries in the input vectors (they are treated
// as sets, so `set_union` deduplicates). Complexity notes assume linear scans.

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

// True iff v contains elem (linear scan).
fn _contains(v: &Vec[Int], elem: Int) -> Bool {
  var i = 0;
  while i < v.len() {
    if v[i] == elem { return true; }
    i = i + 1;
  }
  return false;
}

// True iff a and b share at least one element.
fn _share(a: &Vec[Int], b: &Vec[Int]) -> Bool {
  var i = 0;
  while i < a.len() {
    if _contains(b, a[i]) { return true; }
    i = i + 1;
  }
  return false;
}

// ---------------------------------------------------------------------------
// Binary set operations
// ---------------------------------------------------------------------------

// Union of two sets: every element present in either input, deduplicated.
// Complexity: O((|a| + |b|)^2).
pub fn set_union(a: &Vec[Int], b: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < a.len() {
    if !_contains(&out, a[i]) { out.push(a[i]); }
    i = i + 1;
  }
  var j = 0;
  while j < b.len() {
    if !_contains(&out, b[j]) { out.push(b[j]); }
    j = j + 1;
  }
  return out;
}

// Intersection of two sets: elements present in both inputs, deduplicated.
// Complexity: O(|a| * |b|).
pub fn set_intersection(a: &Vec[Int], b: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < a.len() {
    if _contains(b, a[i]) {
      if !_contains(&out, a[i]) { out.push(a[i]); }
    }
    i = i + 1;
  }
  return out;
}

// Difference of two sets: elements of a not present in b, deduplicated.
// Complexity: O(|a| * |b|).
pub fn set_difference(a: &Vec[Int], b: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < a.len() {
    if !_contains(b, a[i]) {
      if !_contains(&out, a[i]) { out.push(a[i]); }
    }
    i = i + 1;
  }
  return out;
}

// Symmetric difference: elements present in exactly one of the two inputs,
// deduplicated. Complexity: O(|a| * |b| + |b|).
pub fn set_symmetric_difference(a: &Vec[Int], b: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < a.len() {
    if !_contains(b, a[i]) {
      if !_contains(&out, a[i]) { out.push(a[i]); }
    }
    i = i + 1;
  }
  var j = 0;
  while j < b.len() {
    if !_contains(a, b[j]) {
      if !_contains(&out, b[j]) { out.push(b[j]); }
    }
    j = j + 1;
  }
  return out;
}

// ---------------------------------------------------------------------------
// Relations
// ---------------------------------------------------------------------------

// True iff a is a subset of b: every element of a appears in b (duplicates in
// the inputs are ignored). The empty set is a subset of everything.
// Complexity: O(|a| * |b|).
pub fn set_subset(a: &Vec[Int], b: &Vec[Int]) -> Bool {
  var i = 0;
  while i < a.len() {
    if !_contains(b, a[i]) { return false; }
    i = i + 1;
  }
  return true;
}

// True iff a is a superset of b. Complexity: O(|b| * |a|).
pub fn set_superset(a: &Vec[Int], b: &Vec[Int]) -> Bool {
  return set_subset(b, a);
}

// True iff a is a proper subset of b: a is a subset of b and the two sets
// differ in cardinality. Complexity: O(|a| * |b| + |b|).
pub fn set_proper_subset(a: &Vec[Int], b: &Vec[Int]) -> Bool {
  if !set_subset(a, b) { return false; }
  return set_cardinality(a) < set_cardinality(b);
}

// True iff a and b share no element. Complexity: O(|a| * |b|).
pub fn set_disjoint(a: &Vec[Int], b: &Vec[Int]) -> Bool {
  return !_share(a, b);
}

// True iff the blocks form a partition of s: every block is non-empty, the
// blocks are pairwise disjoint, and their union equals s exactly (each element
// of s appears in exactly one block and no block contains an element outside
// s). Complexity: O(|blocks|^2 * max block size + |s| * |blocks|).
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the implementation
// must read elements of a nested Vec[Vec[Int]] (blocks[i][j]), and nested
// Vec element reads are miscompiled (access violation 0xC0000005; see
// docs/COMPILER_BUGS.md BUG 12 family and the collect/graph.xi arena note).
// Even a program that merely links this function crashes before main. Keep
// the frozen signature; revisit when nested Vec[Vec[T]] element reads work.
pub fn set_partition(s: &Vec[Int], blocks: &Vec[Vec[Int]]) -> Bool {
  return false;
}

// ---------------------------------------------------------------------------
// Construction
// ---------------------------------------------------------------------------

// All subsets of s (the power set, 2^n subsets). Returns an empty list when
// |s| > 20 (documented guard against an impractical result set).
// Complexity: O(2^n * n).
pub fn set_power_set(s: &Vec[Int]) -> Vec[Vec[Int]] {
  var out = Vec[Vec[Int]].new();
  var n = s.len();
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
      var check = mask / bitval % 2;
      if check == 1 { sub.push(s[b]); }
      bitval = bitval * 2;
      b = b + 1;
    }
    out.push(sub);
    mask = mask + 1;
  }
  return out;
}

// All ordered pairs (x, y) with x in a and y in b. Complexity: O(|a| * |b|).
pub fn set_cartesian_product(a: &Vec[Int], b: &Vec[Int]) -> Vec[(Int, Int)] {
  var out = Vec[(Int, Int)].new();
  var i = 0;
  while i < a.len() {
    var j = 0;
    while j < b.len() {
      out.push((a[i], b[j]));
      j = j + 1;
    }
    i = i + 1;
  }
  return out;
}

// Number of unique elements in s (duplicates in the input are ignored).
// Complexity: O(|s|^2).
pub fn set_cardinality(s: &Vec[Int]) -> Int {
  var seen = Vec[Int].new();
  var count = 0;
  var i = 0;
  while i < s.len() {
    if !_contains(&seen, s[i]) {
      seen.push(s[i]);
      count = count + 1;
    }
    i = i + 1;
  }
  return count;
}

// Complement of s relative to universe: every element of universe not present
// in s. Complexity: O(|universe| * |s|).
pub fn set_complement(s: &Vec[Int], universe: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < universe.len() {
    if !_contains(s, universe[i]) { out.push(universe[i]); }
    i = i + 1;
  }
  return out;
}

// Elements of universe satisfying the predicate pred, in universe order.
// Complexity: O(|universe| * pred).
pub fn set_comprehension(pred: fn(Int) -> Bool, universe: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < universe.len() {
    if pred(universe[i]) { out.push(universe[i]); }
    i = i + 1;
  }
  return out;
}
