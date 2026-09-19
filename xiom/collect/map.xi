// XIOM - Collections: Open-Addressing HashIntMap
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.map

// Depends on: none

// ============================================================================
// Hash HashIntMap with open addressing over Int keys and Int values.
//
// Open addressing with linear probing and tombstones. Buckets live in three
// parallel vectors: `keys`, `values` and `states` (0 = empty, 1 = occupied,
// 2 = tombstone). The table starts at capacity 16 and doubles when the load
// factor exceeds 0.75.
// ============================================================================

const state_empty: Int = 0;
const state_occupied: Int = 1;
const state_tombstone: Int = 2;

/// An open-addressing hash HashIntMap from Int keys to Int values.
pub type HashIntMap = {
  keys: Vec[Int];
  values: Vec[Int];
  states: Vec[Int];
  used: Int;
}

/// Create a new empty HashIntMap (capacity 16).
/// Complexity: O(1).
pub fn map_new() -> HashIntMap
  ensures: result.used == 0
{
  var keys = Vec[Int].new();
  var values = Vec[Int].new();
  var states = Vec[Int].new();
  var i: Int = 0;
  while i < 16 {
    keys.push(0);
    values.push(0);
    states.push(0);
    i = i + 1;
  };
  HashIntMap{ keys: keys; values: values; states: states; used: 0; }
}

/// Bucket index for a key.
fn bucket_for(m: &HashIntMap, key: Int) -> Int {
  var h = key;
  if h < 0 {
    h = -h;
  };
  h % m.states.len()
}

/// True when the load factor exceeds 0.75.
fn needs_grow(m: &HashIntMap) -> Bool {
  let cap = m.states.len();
  m.used * 4 > cap * 3
}

/// Rebuild the table with double capacity.
fn grow(m: &mut HashIntMap) {
  let old_keys = m.keys;
  let old_values = m.values;
  let old_states = m.states;
  let cap = old_states.len();
  m.keys = Vec[Int].new();
  m.values = Vec[Int].new();
  m.states = Vec[Int].new();
  var i: Int = 0;
  while i < cap * 2 {
    m.keys.push(0);
    m.values.push(0);
    m.states.push(0);
    i = i + 1;
  };
  m.used = 0;
  i = 0;
  while i < cap {
    if old_states[i] == state_occupied {
      put_internal(m, old_keys[i], old_values[i]);
    };
    i = i + 1;
  };
}

/// Insert without load-factor handling (used by grow).
fn put_internal(m: &mut HashIntMap, key: Int, value: Int) {
  let cap = m.states.len();
  var idx = key;
  if idx < 0 {
    idx = -idx;
  };
  idx = idx % cap;
  var first_tomb: Int = -1;
  var i: Int = 0;
  while i < cap {
    if m.states[idx] == state_empty {
      if first_tomb >= 0 {
        idx = first_tomb;
      };
      m.keys[idx] = key;
      m.values[idx] = value;
      m.states[idx] = state_occupied;
      m.used = m.used + 1;
      return;
    };
    if m.states[idx] == state_occupied && m.keys[idx] == key {
      m.values[idx] = value;
      return;
    };
    if m.states[idx] == state_tombstone && first_tomb < 0 {
      first_tomb = idx;
    };
    idx = (idx + 1) % cap;
    i = i + 1;
  };
  if first_tomb >= 0 {
    m.keys[first_tomb] = key;
    m.values[first_tomb] = value;
    m.states[first_tomb] = state_occupied;
    m.used = m.used + 1;
  };
}

/// Insert or update a key. Grows the table when the load factor exceeds 0.75.
/// Complexity: O(1) amortized.
pub fn map_put(m: &mut HashIntMap, key: Int, value: Int)
  ensures: m.used >= 1
{
  if needs_grow(m) {
    grow(m);
  };
  put_internal(m, key, value);
}

/// Get the value for a key.
/// Complexity: O(1) average.
pub fn map_get(m: &HashIntMap, key: Int) -> Option[Int] {
  let cap = m.states.len();
  var idx = key;
  if idx < 0 {
    idx = -idx;
  };
  idx = idx % cap;
  var i: Int = 0;
  while i < cap {
    if m.states[idx] == state_empty {
      return None;
    };
    if m.states[idx] == state_occupied && m.keys[idx] == key {
      return Some(m.values[idx]);
    };
    idx = (idx + 1) % cap;
    i = i + 1;
  };
  None
}

/// Check whether a key is present.
/// Complexity: O(1) average.
pub fn map_contains(m: &HashIntMap, key: Int) -> Bool {
  let found = map_get(m, key);
  found.is_some
}

/// Remove a key, returning whether it was present (the bucket becomes a
/// tombstone).
/// Complexity: O(1) average.
pub fn map_remove(m: &mut HashIntMap, key: Int) -> Bool
  ensures: m.used >= 0
{
  let cap = m.states.len();
  var idx = key;
  if idx < 0 {
    idx = -idx;
  };
  idx = idx % cap;
  var i: Int = 0;
  while i < cap {
    if m.states[idx] == state_empty {
      return false;
    };
    if m.states[idx] == state_occupied && m.keys[idx] == key {
      m.states[idx] = state_tombstone;
      m.used = m.used - 1;
      return true;
    };
    idx = (idx + 1) % cap;
    i = i + 1;
  };
  false
}

/// Number of entries.
/// Complexity: O(1).
pub fn map_size(m: &HashIntMap) -> Int
  ensures: result >= 0
{
  m.used
}

/// Collect all keys.
/// Complexity: O(capacity).
pub fn map_keys(m: &HashIntMap) -> Vec[Int]
  ensures: result.len() == map_size(m)
{
  var out = Vec[Int].new();
  var i: Int = 0;
  while i < m.states.len() {
    if m.states[i] == state_occupied {
      out.push(m.keys[i]);
    };
    i = i + 1;
  };
  out
}

/// Remove all entries.
/// Complexity: O(capacity).
pub fn map_clear(m: &mut HashIntMap)
  ensures: m.used == 0
{
  var i: Int = 0;
  while i < m.states.len() {
    m.states[i] = state_empty;
    i = i + 1;
  };
  m.used = 0;
}

/// Rebuild the table IN PLACE at the same capacity, clearing tombstones
/// and restoring contiguous probe sequences. Call after heavy
/// delete+insert workloads, where tombstone density between automatic
/// grows can degrade lookups toward O(capacity) linear scans.
/// Complexity: O(capacity).
pub fn map_rehash(m: &mut HashIntMap) {
  let cap = m.states.len();
  let old_keys = m.keys;
  let old_values = m.values;
  let old_states = m.states;
  m.keys = Vec[Int].new();
  m.values = Vec[Int].new();
  m.states = Vec[Int].new();
  var i: Int = 0;
  while i < cap {
    m.keys.push(0);
    m.values.push(0);
    m.states.push(0);
    i = i + 1;
  };
  m.used = 0;
  i = 0;
  while i < cap {
    if old_states[i] == state_occupied {
      put_internal(m, old_keys[i], old_values[i]);
    };
    i = i + 1;
  };
}

/// Check whether the HashIntMap has no entries.
/// Complexity: O(1).
pub fn map_is_empty(m: &HashIntMap) -> Bool
  ensures: result == (map_size(m) == 0)
{
  m.used == 0
}
