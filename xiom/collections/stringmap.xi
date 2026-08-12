// XIOM - Collections: String Map
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.stringmap

// Depends on: xiom.string

// ============================================================================
// Hash map with string keys and Int values.
// Separate chaining with Str keys; the bucket index comes from a djb2 hash of
// the key bytes (via xiom.string.byte_at/byte_count). Entries live in
// parallel `keys` (Str) / `values` (Int) / `next` / `live` arenas; removed
// entries are unlinked and flagged dead but stay in the arena. The table
// doubles when the load factor exceeds 0.75, re-linking only live entries.
// ============================================================================

use xiom.string;

pub type StringMap = {
  buckets: Vec[Int];
  keys: Vec[Str];
  values: Vec[Int];
  next: Vec[Int];
  live: Vec[Bool];
  count: Int;
}

const _SMAP_INITIAL: Int = 8;

// djb2 hash over the bytes of `key`, folded to a non-negative value.
fn _hash_str(key: Str) -> Int {
  var hash: Int = 5381;
  var n = byte_count(key);
  var i: Int = 0;
  while i < n {
    var b = byte_at(key, i) as Int;
    hash = ((hash * 33) + b) & 0xFFFFFFFF;
    i = i + 1;
  }
  if hash < 0 { hash = -hash; }
  return hash;
}

fn _bucket(m: &StringMap, key: Str) -> Int {
  var h = _hash_str(key);
  return h % m.buckets.len();
}

/// Create a new empty string map.
/// Returns: a map with a small initial table and zero entries.
/// Complexity: O(1).
pub fn string_map_new() -> StringMap {
  var buckets = Vec[Int].new();
  var i: Int = 0;
  while i < _SMAP_INITIAL {
    buckets.push(-1);
    i = i + 1;
  }
  return StringMap{ buckets: buckets; keys: Vec[Str].new(); values: Vec[Int].new(); next: Vec[Int].new(); live: Vec[Bool].new(); count: 0; };
}

// Entry index for `key`, or -1 if absent.
fn _find(m: &StringMap, key: Str) -> Int {
  var b = _bucket(m, key);
  var e = m.buckets[b];
  while e != -1 {
    var k = m.keys[e];
    if k == key {
      return e;
    }
    e = m.next[e];
  }
  return -1;
}

// Double the table and re-link every live entry into the new buckets.
fn _grow(m: &mut StringMap) {
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
      var k = m.keys[i];
      var b = _hash_str(k) % nb;
      m.next[i] = new_buckets[b];
      new_buckets[b] = i;
    }
    i = i + 1;
  }
  m.buckets = new_buckets;
}

/// Insert or update `key` -> `value`.
/// Params: m - the map; key - Str key; value - Int value.
/// Re-inserting an existing key updates its value.
/// Complexity: O(1) amortized.
pub fn string_map_put(m: &mut StringMap, key: Str, value: Int) {
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
/// Params: m - the map; key - Str key.
/// Returns: Some(value) if present, None otherwise.
/// Complexity: O(1) amortized.
pub fn string_map_get(m: &StringMap, key: Str) -> Option[Int] {
  var idx = _find(m, key);
  if idx < 0 { return None; }
  return Some(m.values[idx]);
}

/// Check whether a key is present.
/// Params: m - the map; key - Str key.
/// Returns: true if `key` maps to a value.
/// Complexity: O(1) amortized.
pub fn string_map_contains(m: &StringMap, key: Str) -> Bool {
  return _find(m, key) >= 0;
}

/// Remove a key.
/// Params: m - the map; key - Str key.
/// Absent keys are a no-op. Arena memory is retained.
/// Complexity: O(1) amortized.
pub fn string_map_remove(m: &mut StringMap, key: Str) {
  var b = _bucket(m, key);
  var prev: Int = -1;
  var e = m.buckets[b];
  while e != -1 {
    var k = m.keys[e];
    if k == key {
      if prev == -1 {
        m.buckets[b] = m.next[e];
      } else {
        m.next[prev] = m.next[e];
      }
      m.live[e] = false;
      m.count = m.count - 1;
      return;
    }
    prev = e;
    e = m.next[e];
  }
}

/// Number of entries.
/// Params: m - the map.
/// Returns: the number of live key/value pairs.
/// Complexity: O(1).
pub fn string_map_size(m: &StringMap) -> Int {
  return m.count;
}
