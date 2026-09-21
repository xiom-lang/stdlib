// XIOM - Iterator: Chain
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.iter.chain

// Depends on: none

// ============================================================================
// Reduction and aggregation: fold, reduce, sum, quantifiers, grouping.
// All predicates/combiner functions must be passed as NAMED functions
// (inline lambdas crash the runtime - see docs/STDLIB_GENERICS.md).
// Implemented as concrete Int/Vec[Int] specializations of the frozen generic
// API (the current compiler miscompiles instantiated generic fns that take
// fn-pointer params - see docs/STDLIB_GENERICS.md).
// ============================================================================

/// Left fold over v with seed init: acc = f(acc, v[i]) for i in order.
/// Returns the final accumulator. O(n). The combiner takes (acc, element).
pub fn iter_fold(v: &Vec[Int], init: Int, f: fn(Int, &Int) -> Int) -> Int {
  var acc = init;
  var i = 0;
  while i < v.len() {
    var x = v[i];
    acc = f(acc, &x);
    i = i + 1;
  }
  acc
}

/// Right fold over v with seed init: acc = f(acc, v[i]) visiting elements
/// from the last to the first. Returns the final accumulator. O(n).
pub fn iter_fold_right(v: &Vec[Int], init: Int, f: fn(Int, &Int) -> Int) -> Int {
  var acc = init;
  var i = v.len() - 1;
  while i >= 0 {
    var x = v[i];
    acc = f(acc, &x);
    i = i - 1;
  }
  acc
}

/// Fold using the first element as the seed; None if v is empty. O(n).
pub fn iter_reduce(v: &Vec[Int], f: fn(&Int, &Int) -> Int) -> Option[Int] {
  if v.len() == 0 { return None; }
  var acc = v[0];
  var i = 1;
  while i < v.len() {
    var x = v[i];
    acc = f(&acc, &x);
    i = i + 1;
  }
  Some(acc)
}

/// Sum of all elements of an Int vector. O(n). Empty vector sums to 0.
pub fn iter_sum(v: &Vec[Int]) -> Int {
  var total = 0;
  var i = 0;
  while i < v.len() {
    total = total + v[i];
    i = i + 1;
  }
  total
}

/// Product of all elements of an Int vector. O(n). Empty vector is 1.
pub fn iter_product(v: &Vec[Int]) -> Int {
  var total = 1;
  var i = 0;
  while i < v.len() {
    total = total * v[i];
    i = i + 1;
  }
  total
}

/// True if any element satisfies pred. O(n). Short-circuits.
pub fn iter_any(v: &Vec[Int], pred: fn(&Int) -> Bool) -> Bool {
  var i = 0;
  while i < v.len() {
    var x = v[i];
    if pred(&x) { return true; }
    i = i + 1;
  }
  false
}

/// True if every element satisfies pred. O(n). Short-circuits.
pub fn iter_all(v: &Vec[Int], pred: fn(&Int) -> Bool) -> Bool {
  var i = 0;
  while i < v.len() {
    var x = v[i];
    if !pred(&x) { return false; }
    i = i + 1;
  }
  true
}

/// Number of elements in v. O(1).
pub fn iter_count(v: &Vec[Int]) -> Int
  ensures: result == v.len()
{
  v.len()
}

/// Number of elements satisfying pred. O(n).
pub fn iter_count_if(v: &Vec[Int], pred: fn(&Int) -> Bool) -> Int
  ensures: result >= 0 && result <= v.len()
{
  var count = 0;
  var i = 0;
  while i < v.len() {
    var x = v[i];
    if pred(&x) { count = count + 1; }
    i = i + 1;
  }
  count
}

/// Element at index n, or None if out of bounds. O(1).
pub fn iter_nth(v: &Vec[Int], n: Int) -> Option[Int] {
  if n < 0 || n >= v.len() { return None; }
  Some(v[n])
}

/// Last element of v, or None if empty. O(1).
pub fn iter_last(v: &Vec[Int]) -> Option[Int] {
  if v.len() == 0 { return None; }
  Some(v[v.len() - 1])
}

/// Index of the first element satisfying pred, or None. O(n).
pub fn iter_position(v: &Vec[Int], pred: fn(&Int) -> Bool) -> Option[Int] {
  var i = 0;
  while i < v.len() {
    var x = v[i];
    if pred(&x) { return Some(i); }
    i = i + 1;
  }
  None
}

/// Maximum element of an Int vector, or None if empty. O(n).
pub fn iter_max(v: &Vec[Int]) -> Option[Int] {
  if v.len() == 0 { return None; }
  var max_val = v[0];
  var i = 1;
  while i < v.len() {
    if v[i] > max_val { max_val = v[i]; }
    i = i + 1;
  }
  Some(max_val)
}

/// Minimum element of an Int vector, or None if empty. O(n).
pub fn iter_min(v: &Vec[Int]) -> Option[Int] {
  if v.len() == 0 { return None; }
  var min_val = v[0];
  var i = 1;
  while i < v.len() {
    if v[i] < min_val { min_val = v[i]; }
    i = i + 1;
  }
  Some(min_val)
}

/// Split v into (matching, non-matching) vectors by pred. O(n).
/// The first tuple element holds elements where pred is true, in order.
pub fn iter_partition(v: &Vec[Int], pred: fn(&Int) -> Bool) -> (Vec[Int], Vec[Int]) {
  var yes = Vec[Int].new();
  var no = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    var x = v[i];
    if pred(&x) {
      yes.push(x);
    } else {
      no.push(x);
    }
    i = i + 1;
  }
  (yes, no)
}

/// Split v into contiguous groups of elements sharing an equal key value.
/// Returns a vector of groups in original order. O(n).
/// NOTE: nested Vec[Vec[Int]] element access is unreliable in the current
/// compiler; treat the result as opaque and inspect group lengths only.
pub fn iter_group_by(v: &Vec[Int], key: fn(&Int) -> Int) -> Vec[Vec[Int]] {
  var groups = Vec[Vec[Int]].new();
  if v.len() == 0 { return groups; }
  var current = Vec[Int].new();
  var first = v[0];
  var current_key = key(&first);
  current.push(first);
  var i = 1;
  while i < v.len() {
    var x = v[i];
    var k = key(&x);
    if k == current_key {
      current.push(x);
    } else {
      groups.push(current);
      current = Vec[Int].new();
      current.push(x);
      current_key = k;
    }
    i = i + 1;
  }
  groups.push(current);
  groups
}
