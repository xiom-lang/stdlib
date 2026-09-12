// XIOM - Collections: Sparse Set
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.sparse

// Depends on: none

// ============================================================================
// Sparse set of unique Int elements with O(1) add, remove and membership
// checks over dense Int universes.
//
// Classic two-array representation: `sparse[value]` holds the index of
// `value` inside `dense`, and `dense` holds the set members in an arbitrary
// but stable order. Removal swaps the last element into the removed slot, so
// all three core operations are O(1). The `sparse` array grows on demand to
// cover the largest inserted value; negative values cannot be indexed and are
// therefore rejected by `sparse_add` (documented, no silent failure).
// ============================================================================

pub type SparseSet = {
  sparse: Vec[Int];
  dense: Vec[Int];
}

// Grow the sparse array so `upto` is a valid index (filled with -1).
fn _grow(s: &mut SparseSet, upto: Int) {
  while s.sparse.len() <= upto {
    s.sparse.push(-1);
  }
}

fn _contains_at(s: &SparseSet, value: Int) -> Bool {
  if value < 0 || value >= s.sparse.len() {
    return false;
  }
  var idx = s.sparse[value];
  if idx < 0 || idx >= s.dense.len() {
    return false;
  }
  return s.dense[idx] == value;
}

/// Create a new empty sparse set.
/// O(1).
pub fn sparse_set_new() -> SparseSet {
  return SparseSet{ sparse: Vec[Int].new(); dense: Vec[Int].new(); };
}

/// Add a value to the set (no-op if already present). Negative values are
/// rejected (they cannot be indexed in the sparse array).
/// O(1) amortized.
pub fn sparse_add(s: &mut SparseSet, value: Int) {
  if value < 0 {
    return;
  }
  _grow(s, value);
  if _contains_at(s, value) {
    return;
  }
  s.sparse[value] = s.dense.len();
  s.dense.push(value);
}

/// Check whether a value is present.
/// O(1).
pub fn sparse_contains(s: &SparseSet, value: Int) -> Bool {
  return _contains_at(s, value);
}

/// Remove a value from the set (no-op if absent).
/// O(1) amortized.
pub fn sparse_remove(s: &mut SparseSet, value: Int) {
  if !_contains_at(s, value) {
    return;
  }
  var idx = s.sparse[value];
  var last = s.dense[s.dense.len() - 1];
  s.dense[idx] = last;
  s.sparse[last] = idx;
  s.dense.pop();
  s.sparse[value] = -1;
}

/// Number of elements in the set.
/// O(1).
pub fn sparse_size(s: &SparseSet) -> Int {
  return s.dense.len();
}

/// Iterate all elements (arbitrary but stable order).
/// O(n).
pub fn sparse_iter(s: &SparseSet) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < s.dense.len() {
    out.push(s.dense[i]);
    i = i + 1;
  }
  return out;
}
