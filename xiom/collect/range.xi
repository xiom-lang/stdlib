// XIOM - Collections: Interval Tree
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.range

// Depends on: none

/// Interval tree storing Int intervals with values, supporting point queries.
/// 
/// R44 same-leaf: the public type leaf here is `IntervalSet` (renamed from
/// `IntervalTree`, which collided with the real tree in collect/interval.xi).
/// Function names stay `interval_*`; both modules share the call surface, so
/// always `use` the module you call.
/// 
/// Flat-arena style. Intervals are stored in insertion order in parallel
/// Vec[Int]s (`starts`/`ends`/`vals`) with a parallel liveness flag `alive`.
/// Point queries scan the intervals and return the values of the live intervals
/// covering the point; removal marks the first matching interval dead (lazy
/// deletion). This keeps the API simple and insertion/removal O(1) amortized
/// at the cost of O(n) queries, which is appropriate for the small interval
/// sets this module targets. Intervals are inclusive on both ends; `start > end`
/// intervals are rejected by insert.
pub type IntervalSet = {
  starts: Vec[Int];
  ends: Vec[Int];
  vals: Vec[Int];
  alive: Vec[Bool];
}

/// Create a new empty interval tree.
/// O(1).
pub fn interval_tree_new() -> IntervalSet {
  return IntervalSet{ starts: Vec[Int].new(); ends: Vec[Int].new(); vals: Vec[Int].new(); alive: Vec[Bool].new(); };
}

/// Insert an interval with its value. Duplicate intervals are allowed; an
/// interval with start > end is rejected (ignored).
/// O(1) amortized.
pub fn interval_insert(t: &mut IntervalSet, start: Int, end: Int, value: Int) {
  if start > end {
    return;
  }
  t.starts.push(start);
  t.ends.push(end);
  t.vals.push(value);
  t.alive.push(true);
}

/// Values of the live intervals covering `point` (inclusive on both ends).
/// O(n).
pub fn interval_query(t: &IntervalSet, point: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < t.starts.len() {
    if t.alive[i] {
      if t.starts[i] <= point && t.ends[i] >= point {
        out.push(t.vals[i]);
      }
    }
    i = i + 1;
  }
  return out;
}

/// Remove the first live interval matching [start, end]. Returns true if one
/// was found and removed.
/// O(n).
pub fn interval_remove(t: &mut IntervalSet, start: Int, end: Int) -> Bool {
  var i = 0;
  while i < t.starts.len() {
    if t.alive[i] {
      if t.starts[i] == start && t.ends[i] == end {
        t.alive[i] = false;
        return true;
      }
    }
    i = i + 1;
  }
  return false;
}
