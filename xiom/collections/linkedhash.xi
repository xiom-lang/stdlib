// XIOM - Collections: Insertion-Ordered Hash Map
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.linkedhash

// Depends on: none

// ============================================================================
// Hash map preserving insertion order of Int keys. Keys and values live in
// two parallel Vec[Int]s in insertion order: putting an existing key updates
// its value without moving it; putting a new key appends. `lhmap_first`/
// `lhmap_last`/`lhmap_iter` read that order. Lookup is a linear scan (O(n)),
// which keeps the API dependency-free; removal compacts the vectors.
// ============================================================================

pub type LhMap = {
  keys: Vec[Int];
  values: Vec[Int];
}

/// Create a new empty insertion-ordered map. O(1).
pub fn lhmap_new() -> LhMap {
  return LhMap{ keys: Vec[Int].new(); values: Vec[Int].new(); };
}

/// Index of `key`, or -1 when absent. O(n).
fn lhmap_find(m: &LhMap, key: Int) -> Int {
  var i: Int = 0;
  while i < m.keys.len() {
    if m.keys[i] == key { return i; }
    i = i + 1;
  }
  return -1;
}

/// Insert or update `key` -> `value`. New keys are appended in insertion
/// order; updating keeps the existing position. O(n).
pub fn lhmap_put(m: &mut LhMap, key: Int, value: Int) {
  var idx = lhmap_find(m, key);
  if idx >= 0 {
    m.values[idx] = value;
    return;
  }
  m.keys.push(key);
  m.values.push(value);
}

/// Value for `key`, or None when absent. O(n).
pub fn lhmap_get(m: &LhMap, key: Int) -> Option[Int] {
  var idx = lhmap_find(m, key);
  if idx < 0 { return None; }
  return Some(m.values[idx]);
}

/// True if `key` is present. O(n).
pub fn lhmap_contains(m: &LhMap, key: Int) -> Bool {
  return lhmap_find(m, key) >= 0;
}

/// Remove `key` if present, preserving the relative order of the remaining
/// entries. O(n).
pub fn lhmap_remove(m: &mut LhMap, key: Int) {
  var idx = lhmap_find(m, key);
  if idx < 0 { return; }
  var j = idx;
  while j + 1 < m.keys.len() {
    m.keys[j] = m.keys[j + 1];
    m.values[j] = m.values[j + 1];
    j = j + 1;
  }
  m.keys.pop();
  m.values.pop();
}

/// Number of entries in the map. O(1).
pub fn lhmap_size(m: &LhMap) -> Int {
  var len = m.keys.len();
  return len;
}

/// First key in insertion order, or None when the map is empty. O(1).
pub fn lhmap_first(m: &LhMap) -> Option[Int] {
  if m.keys.len() == 0 { return None; }
  return Some(m.keys[0]);
}

/// Last key in insertion order, or None when the map is empty. O(1).
pub fn lhmap_last(m: &LhMap) -> Option[Int] {
  if m.keys.len() == 0 { return None; }
  var last = m.keys.len() - 1;
  return Some(m.keys[last]);
}

/// All keys in insertion order. O(n).
pub fn lhmap_iter(m: &LhMap) -> Vec[Int] {
  var result = Vec[Int].new();
  var i: Int = 0;
  while i < m.keys.len() {
    result.push(m.keys[i]);
    i = i + 1;
  }
  return result;
}
