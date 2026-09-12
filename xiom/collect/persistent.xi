// XIOM - Collections: Persistent Collections
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.persistent

// Depends on: none (pure)

// ============================================================================
// Persistent (copy-on-write) collections. Every update returns a new structure
// and leaves the original intact, enabling cheap immutability and undo/history.
// Int-valued elements and key/value pairs; accessors return Option[Int].
// ============================================================================

pub type PVec = {
  items: Vec[Int];
}

pub type PMap = {
  keys: Vec[Int];
  values: Vec[Int];
}

/// Create an empty persistent vector.
/// Returns: an empty PVec.
/// Complexity: O(1).
pub fn persistent_vec_new() -> PVec {
  return PVec{ items: Vec[Int].new(); };
}

/// Append item, returning a new vector. The input vector is left intact.
/// Params: v - the source vector; item - Int element to append.
/// Returns: a new PVec holding the original elements plus `item`.
/// Complexity: O(n).
pub fn pvec_push(v: &PVec, item: Int) -> PVec {
  var nv = Vec[Int].new();
  var i: Int = 0;
  while i < v.items.len() {
    nv.push(v.items[i]);
    i = i + 1;
  }
  nv.push(item);
  return PVec{ items: nv; };
}

/// Element at idx, or None if out of range.
/// Params: v - the vector; idx - zero-based index.
/// Returns: Some(element) if in range, None otherwise.
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

/// Replace element at idx, returning a new vector.
/// Params: v - the source vector; idx - zero-based index; value - new element.
/// Returns: a new PVec with `value` at `idx`; out-of-range indices yield a
/// copy of `v` unchanged.
/// Complexity: O(n).
pub fn pvec_update(v: &PVec, idx: Int, value: Int) -> PVec {
  var nv = Vec[Int].new();
  var i: Int = 0;
  while i < v.items.len() {
    if i == idx {
      nv.push(value);
    } else {
      nv.push(v.items[i]);
    }
    i = i + 1;
  }
  return PVec{ items: nv; };
}

/// Create an empty persistent map.
/// Returns: an empty PMap.
/// Complexity: O(1).
pub fn persistent_map_new() -> PMap {
  return PMap{ keys: Vec[Int].new(); values: Vec[Int].new(); };
}

/// Insert key/value, returning a new map. The input map is left intact.
/// Params: m - the source map; key - Int key; value - Int value.
/// Returns: a new PMap with the key inserted or updated.
/// Complexity: O(n).
pub fn pmap_put(m: &PMap, key: Int, value: Int) -> PMap {
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
  return PMap{ keys: nk; values: nv; };
}

/// Value for key, or None.
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

/// Remove key, returning a new map. The input map is left intact.
/// Params: m - the source map; key - Int key.
/// Returns: a new PMap without `key` (an equivalent copy if absent).
/// Complexity: O(n).
pub fn pmap_remove(m: &PMap, key: Int) -> PMap {
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
  return PMap{ keys: nk; values: nv; };
}
