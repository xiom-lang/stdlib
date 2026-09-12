// XIOM - Collections: Chaining Hash Map
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.mapch

// Depends on: none

// ============================================================================
// Hash map using separate chaining over Int keys and Int values.
// Bucket heads live in `buckets`; entries are stored in parallel `keys` /
// `values` / `next` / `live` arenas (the flat-arena collect/ pattern).
// Removed entries are unlinked and flagged dead but stay in the arena, so
// chain walkers never see them. The table doubles when the load factor
// exceeds 0.75, re-linking only live entries. O(1) amortized lookups.
// ============================================================================

pub type HashMap = {
  buckets: Vec[Int];
  keys: Vec[Int];
  values: Vec[Int];
  next: Vec[Int];
  live: Vec[Bool];
  count: Int;
}

const _MAPCH_INITIAL: Int = 8;

// SplitMix64-style finalizer for deterministic integer hashing.
fn _hash(key: Int) -> Int {
  var z = key + 0x9E3779B97F4A7C15;
  z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9;
  z = (z ^ (z >> 27)) * 0x94D049BB133111EB;
  z = z ^ (z >> 31);
  if z < 0 { z = -z; }
  return z;
}

fn _bucket(m: &HashMap, key: Int) -> Int {
  var h = _hash(key);
  return h % m.buckets.len();
}

/// Create a new empty chaining hash map.
/// Returns: a map with a small initial table and zero entries.
/// Complexity: O(1).
pub fn hashmap_new() -> HashMap {
  var buckets = Vec[Int].new();
  var i: Int = 0;
  while i < _MAPCH_INITIAL {
    buckets.push(-1);
    i = i + 1;
  }
  return HashMap{ buckets: buckets; keys: Vec[Int].new(); values: Vec[Int].new(); next: Vec[Int].new(); live: Vec[Bool].new(); count: 0; };
}

// Entry index for `key`, or -1 if absent.
fn _find(m: &HashMap, key: Int) -> Int {
  var b = _bucket(m, key);
  var e = m.buckets[b];
  while e != -1 {
    if m.keys[e] == key {
      return e;
    }
    e = m.next[e];
  }
  return -1;
}

// Double the table and re-link every live entry into the new buckets.
fn _grow(m: &mut HashMap) {
  var nb = m.buckets.len() * 2;
  var new_buckets = Vec[Int].new();
  var i: Int = 0;
  while i < nb {
    new_buckets.push(-1);
    i = i + 1;
  }
  i = 0;
  while i < m.keys.len() {
    if m.live[i] {
      var b = _hash(m.keys[i]) % nb;
      m.next[i] = new_buckets[b];
      new_buckets[b] = i;
    }
    i = i + 1;
  }
  m.buckets = new_buckets;
}

/// Insert or update `key` -> `value`.
/// Params: m - the map; key - Int key; value - Int value.
/// Complexity: O(1) amortized.
pub fn hashmap_put(m: &mut HashMap, key: Int, value: Int) {
  var idx = _find(m, key);
  if idx >= 0 {
    m.values[idx] = value;
    return;
  }
  if m.count * 4 > m.buckets.len() * 3 {
    _grow(m);
  }
  var b = _bucket(m, key);
  var id = m.keys.len();
  m.keys.push(key);
  m.values.push(value);
  m.next.push(m.buckets[b]);
  m.live.push(true);
  m.buckets[b] = id;
  m.count = m.count + 1;
}

/// Get the value for a key. None when absent.
/// Params: m - the map; key - Int key.
/// Returns: Some(value) if present, None otherwise.
/// Complexity: O(1) amortized.
pub fn hashmap_get(m: &HashMap, key: Int) -> Option[Int] {
  var idx = _find(m, key);
  if idx < 0 { return None; }
  return Some(m.values[idx]);
}

/// Check whether a key is present.
/// Params: m - the map; key - Int key.
/// Returns: true if `key` maps to a value.
/// Complexity: O(1) amortized.
pub fn hashmap_contains(m: &HashMap, key: Int) -> Bool {
  return _find(m, key) >= 0;
}

/// Remove a key, returning whether it was present.
/// Params: m - the map; key - Int key.
/// Returns: true if the key was present and is now removed.
/// Complexity: O(1) amortized.
pub fn hashmap_remove(m: &mut HashMap, key: Int) -> Bool {
  var b = _bucket(m, key);
  var prev: Int = -1;
  var e = m.buckets[b];
  while e != -1 {
    if m.keys[e] == key {
      if prev == -1 {
        m.buckets[b] = m.next[e];
      } else {
        m.next[prev] = m.next[e];
      }
      m.live[e] = false;
      m.count = m.count - 1;
      return true;
    }
    prev = e;
    e = m.next[e];
  }
  return false;
}

/// Number of entries.
/// Params: m - the map.
/// Returns: the number of live key/value pairs.
/// Complexity: O(1).
pub fn hashmap_size(m: &HashMap) -> Int {
  return m.count;
}

/// Remove all entries.
/// Params: m - the map.
/// Complexity: O(1) (the table is re-initialised; arena memory is retained).
pub fn hashmap_clear(m: &mut HashMap) {
  var i: Int = 0;
  while i < m.buckets.len() {
    m.buckets[i] = -1;
    i = i + 1;
  }
  i = 0;
  while i < m.live.len() {
    m.live[i] = false;
    i = i + 1;
  }
  m.count = 0;
}
