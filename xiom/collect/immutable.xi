// XIOM - Collections: Persistent Data Structures
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.collect.immutable

// Depends on: none

// ============================================================================
// Persistent (copy-on-write) vector and map retaining prior versions.
// Every update copies the backing arena into a fresh Vec before mutating, so
// any caller holding an older PVec/PMap value still observes the version it
// captured. Int elements; accessors return Option[Int].
// ============================================================================

pub type PVec = {
  items: Vec[Int];
}

pub type PMap = {
  keys: Vec[Int];
  values: Vec[Int];
}

/// Create a new empty persistent vector.
/// Returns: an empty PVec.
/// Complexity: O(1).
pub fn persistent_vec_new() -> PVec {
  return PVec{ items: Vec[Int].new(); };
}

/// Append a value, returning a new version (copy-on-write).
/// Params: v - the vector; value - Int element to append.
/// The backing Vec is rebuilt, leaving any previously captured PVec intact.
/// Complexity: O(n).
pub fn pvec_push(v: &mut PVec, value: Int) {
  var nv = Vec[Int].new();
  var i: Int = 0;
  while i < v.items.len() {
    nv.push(v.items[i]);
    i = i + 1;
  }
  nv.push(value);
  v.items = nv;
}

/// Get the value at an index. None when out of range.
/// Params: v - the vector; idx - zero-based index.
/// Returns: Some(element) if idx is in range, None otherwise.
/// Complexity: O(1).
pub fn pvec_get(v: &PVec, idx: Int) -> Option[Int] {
  if idx < 0 || idx >= v.items.len() { return None; }
  return Some(v.items[idx]);
}

/// Number of elements.
/// Params: v - the vector.
/// Returns: the number of elements.
/// Complexity: O(1).
pub fn pvec_len(v: &PVec) -> Int
  ensures: result >= 0
{
  return v.items.len();
}

/// Create a new empty persistent map.
/// Returns: an empty PMap.
/// Complexity: O(1).
pub fn persistent_map_new() -> PMap {
  return PMap{ keys: Vec[Int].new(); values: Vec[Int].new(); };
}

/// Insert or update a key (copy-on-write).
/// Params: m - the map; key - Int key; value - Int value.
/// The backing arenas are rebuilt, leaving any previously captured PMap intact.
/// Complexity: O(n).
pub fn pmap_put(m: &mut PMap, key: Int, value: Int) {
  var nk = Vec[Int].new();
  var nv = Vec[Int].new();
  var found = false;
  var i: Int = 0;
  while i < m.keys.len() {
    var k = m.keys[i];
    if k == key {
      nk.push(key);
      nv.push(value);
      found = true;
    } else {
      nk.push(k);
      nv.push(m.values[i]);
    }
    i = i + 1;
  }
  if !found {
    nk.push(key);
    nv.push(value);
  }
  m.keys = nk;
  m.values = nv;
}

/// Get the value for a key. None when absent.
/// Params: m - the map; key - Int key.
/// Returns: Some(value) if present, None otherwise.
/// Complexity: O(n).
pub fn pmap_get(m: &PMap, key: Int) -> Option[Int] {
  var i: Int = 0;
  while i < m.keys.len() {
    if m.keys[i] == key {
      return Some(m.values[i]);
    }
    i = i + 1;
  }
  return None;
}

/// Remove a key (copy-on-write).
/// Params: m - the map; key - Int key.
/// Absent keys produce an equivalent copy. Prior versions stay intact.
/// Complexity: O(n).
pub fn pmap_remove(m: &mut PMap, key: Int) {
  var nk = Vec[Int].new();
  var nv = Vec[Int].new();
  var i: Int = 0;
  while i < m.keys.len() {
    var k = m.keys[i];
    if k != key {
      nk.push(k);
      nv.push(m.values[i]);
    }
    i = i + 1;
  }
  m.keys = nk;
  m.values = nv;
}
