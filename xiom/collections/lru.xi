// XIOM - Collections: LRU Cache
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.lru

// Depends on: none

// ============================================================================
// Least-recently-used cache with O(1) get/put over Int keys and values.
//
// Flat-arena style. `keys`/`values` are parallel vectors and `order` is a
// vector of keys in recency order, front = most recently used. `lru_get` and
// `lru_put` move an accessed key to the front; when full, the key at the back
// of `order` (least recently used) is evicted. Lookups are O(n) linear scans
// (the compiler's Vec has no hash map for struct elements), which is
// acceptable for the small cache sizes this module targets.
// ============================================================================

pub type LruCache = {
  capacity: Int;
  keys: Vec[Int];
  values: Vec[Int];
  order: Vec[Int];
}

fn _lru_find(c: &LruCache, key: Int) -> Int {
  var i = 0;
  while i < c.keys.len() {
    if c.keys[i] == key {
      return i;
    }
    i = i + 1;
  }
  return -1;
}

fn _lru_touch(c: &mut LruCache, key: Int) {
  var i = 0;
  while i < c.order.len() {
    if c.order[i] == key {
      c.order.remove(i);
      break;
    }
    i = i + 1;
  }
  c.order.insert(0, key);
}

/// Create a new LRU cache holding at most `capacity` entries.
/// Capacity is clamped to >= 1.
/// O(1).
pub fn lru_new(capacity: Int) -> LruCache {
  var cap = capacity;
  if cap < 1 {
    cap = 1;
  }
  return LruCache{ capacity: cap; keys: Vec[Int].new(); values: Vec[Int].new(); order: Vec[Int].new(); };
}

/// Get the value for `key`, marking it recently used. None if absent.
/// O(n).
pub fn lru_get(c: &mut LruCache, key: Int) -> Option[Int] {
  var idx = _lru_find(c, key);
  if idx < 0 {
    return Option[Int]{ is_some: false; value: 0; };
  }
  var val = c.values[idx];
  _lru_touch(c, key);
  return Option[Int]{ is_some: true; value: val; };
}

/// Insert or update `key` -> `value`, evicting the least-recently-used entry
/// when full.
/// O(n).
pub fn lru_put(c: &mut LruCache, key: Int, value: Int) {
  var idx = _lru_find(c, key);
  if idx >= 0 {
    c.values[idx] = value;
    _lru_touch(c, key);
    return;
  }
  if c.keys.len() >= c.capacity {
    var victim = c.order[c.order.len() - 1];
    var vi = _lru_find(c, victim);
    if vi >= 0 {
      c.keys.remove(vi);
      c.values.remove(vi);
    }
    c.order.pop();
  }
  c.keys.push(key);
  c.values.push(value);
  _lru_touch(c, key);
}

/// Check whether `key` is present (does not change recency).
/// O(n).
pub fn lru_contains(c: &mut LruCache, key: Int) -> Bool {
  return _lru_find(c, key) >= 0;
}

/// Remove `key`, returning whether it was present.
/// O(n).
pub fn lru_remove(c: &mut LruCache, key: Int) -> Bool {
  var idx = _lru_find(c, key);
  if idx < 0 {
    return false;
  }
  c.keys.remove(idx);
  c.values.remove(idx);
  var i = 0;
  while i < c.order.len() {
    if c.order[i] == key {
      c.order.remove(i);
      break;
    }
    i = i + 1;
  }
  return true;
}

/// Number of entries currently cached.
/// O(1).
pub fn lru_size(c: &mut LruCache) -> Int {
  return c.keys.len();
}

/// Maximum number of entries the cache can hold.
/// O(1).
pub fn lru_capacity(c: &mut LruCache) -> Int {
  return c.capacity;
}

/// Remove all entries from the cache.
/// O(1).
pub fn lru_clear(c: &mut LruCache) {
  while c.keys.len() > 0 {
    c.keys.pop();
    c.values.pop();
    c.order.pop();
  }
}
