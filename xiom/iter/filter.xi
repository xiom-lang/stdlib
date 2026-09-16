// XIOM - Iterator: Filter
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.iter.filter

// Depends on: none

// ============================================================================
// Selection adapters: filter, take, skip, dedup, unique.
// Predicates must be passed as NAMED functions (inline lambdas crash the
// runtime - see docs/STDLIB_GENERICS.md). Implemented as concrete Int
// specializations of the frozen generic API (compiler fn-ptr codegen bug).
// ============================================================================

/// New vector with the elements of v satisfying pred, in order. O(n).
pub fn iter_filter(v: &Vec[Int], pred: fn(&Int) -> Bool) -> Vec[Int]
  ensures: result.len() <= v.len()
{
  var out = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    var x = v[i];
    if pred(&x) { out.push(x); }
    i = i + 1;
  }
  out
}

/// Remove in place every element of v not satisfying pred. O(n).
/// Element order is preserved; v is compacted in place.
pub fn iter_filter_mut(v: &mut Vec[Int], pred: fn(&Int) -> Bool) {
  var write = 0;
  var read = 0;
  while read < v.len() {
    var x = v[read];
    if pred(&x) {
      v[write] = x;
      write = write + 1;
    }
    read = read + 1;
  }
  while v.len() > write {
    v.pop();
  }
}

/// First n elements of v (or fewer if v is shorter). O(n).
/// n <= 0 yields an empty vector.
pub fn iter_take(v: &Vec[Int], n: Int) -> Vec[Int]
  ensures: result.len() <= v.len()
{
  var out = Vec[Int].new();
  var count = n;
  if count > v.len() { count = v.len(); }
  var i = 0;
  while i < count {
    out.push(v[i]);
    i = i + 1;
  }
  out
}

/// All elements of v after the first n. O(n). n <= 0 returns all of v.
pub fn iter_skip(v: &Vec[Int], n: Int) -> Vec[Int]
  ensures: result.len() <= v.len()
{
  var out = Vec[Int].new();
  var start = n;
  if start < 0 { start = 0; }
  var i = start;
  while i < v.len() {
    out.push(v[i]);
    i = i + 1;
  }
  out
}

/// The leading run of elements for which pred holds. O(n). Short-circuits.
pub fn iter_take_while(v: &Vec[Int], pred: fn(&Int) -> Bool) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    var x = v[i];
    if !pred(&x) { break; }
    out.push(x);
    i = i + 1;
  }
  out
}

/// Elements of v after the leading run satisfying pred. O(n). Short-circuits.
pub fn iter_skip_while(v: &Vec[Int], pred: fn(&Int) -> Bool) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    var x = v[i];
    if pred(&x) {
      i = i + 1;
    } else {
      break;
    }
  }
  while i < v.len() {
    out.push(v[i]);
    i = i + 1;
  }
  out
}

/// Drop consecutive equal elements from v. O(n).
/// [1,1,2,2,3,1] -> [1,2,3,1].
pub fn iter_dedup(v: &Vec[Int]) -> Vec[Int]
  ensures: result.len() <= v.len()
{
  var out = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    var x = v[i];
    if out.len() == 0 {
      out.push(x);
    } else {
      var last = out[out.len() - 1];
      if x != last {
        out.push(x);
      }
    }
    i = i + 1;
  }
  out
}

/// Keep the first occurrence of each value, dropping later duplicates. O(n^2).
pub fn iter_unique(v: &Vec[Int]) -> Vec[Int]
  ensures: result.len() <= v.len()
{
  var out = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    var x = v[i];
    var seen = false;
    var j = 0;
    while j < out.len() {
      var y = out[j];
      if x == y { seen = true; }
      j = j + 1;
    }
    if !seen { out.push(x); }
    i = i + 1;
  }
  out
}
