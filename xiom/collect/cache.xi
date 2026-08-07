// XIOM — Cache Collection (LRU + LFU)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.cache

// ============================================================================
// LRU Cache (Int keys, Int values)
// Simple bookkeeping: `keys`/`values` are parallel vectors and `order` is a
// vector of keys in recency order, front = most recently used. `lru_get` and
// `lru_put` move an accessed key to the front; when full, the key at the back
// of `order` (least recently used) is evicted.
// ============================================================================

pub type LruCache = {
  capacity: Int;
  keys: Vec[Int];
  values: Vec[Int];
  order: Vec[Int];
}

/// Create an LRU cache holding at most `capacity` entries.
pub fn lru_new(capacity: Int) -> LruCache {
  var cap = capacity;
  if cap < 1 { cap = 1; }
  return LruCache{ capacity: cap; keys: Vec[Int].new(); values: Vec[Int].new(); order: Vec[Int].new(); };
}

/// Move `key` to the front of the recency order (most recently used).
fn lru_touch(c: &mut LruCache, key: Int) {
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

/// Index of `key` in the parallel `keys` vector, or -1 if absent.
fn lru_find(c: &LruCache, key: Int) -> Int {
  var i = 0;
  while i < c.keys.len() {
    if c.keys[i] == key { return i; }
    i = i + 1;
  }
  return -1;
}

/// Fetch a value, marking the key as most recently used. None if absent.
pub fn lru_get(c: &mut LruCache, key: Int) -> Option[Int] {
  var idx = lru_find(c, key);
  if idx < 0 { return None; }
  var val = c.values[idx];
  lru_touch(c, key);
  return Some(val);
}

/// Insert or update a key. Evicts the least recently used key when full.
pub fn lru_put(c: &mut LruCache, key: Int, value: Int) {
  var idx = lru_find(c, key);
  if idx >= 0 {
    c.values[idx] = value;
    lru_touch(c, key);
    return;
  }
  if c.keys.len() >= c.capacity {
    var victim = c.order[c.order.len() - 1];
    var vi = lru_find(c, victim);
    if vi >= 0 {
      c.keys.remove(vi);
      c.values.remove(vi);
    }
    c.order.pop();
  }
  c.keys.push(key);
  c.values.push(value);
  c.order.insert(0, key);
}

/// True if the key is present in the cache.
pub fn lru_contains(c: &LruCache, key: Int) -> Bool {
  return lru_find(c, key) >= 0;
}

/// Number of entries currently cached.
pub fn lru_size(c: &LruCache) -> Int {
  return c.keys.len();
}

/// Maximum number of entries the cache can hold.
pub fn lru_capacity(c: &LruCache) -> Int {
  return c.capacity;
}

// ============================================================================
// LFU Cache (Int keys, Int values)
// Parallel `keys`/`values`/`counts` vectors plus an insertion-sequence vector
// `seq` used as a deterministic tie-break: when several keys share the lowest
// frequency, the least recently inserted one is evicted first.
// ============================================================================

pub type LfuCache = {
  capacity: Int;
  keys: Vec[Int];
  values: Vec[Int];
  counts: Vec[Int];
  seq: Vec[Int];
  next_seq: Int;
}

/// Create an LFU cache holding at most `capacity` entries.
pub fn lfu_new(capacity: Int) -> LfuCache {
  var cap = capacity;
  if cap < 1 { cap = 1; }
  return LfuCache{ capacity: cap; keys: Vec[Int].new(); values: Vec[Int].new(); counts: Vec[Int].new(); seq: Vec[Int].new(); next_seq: 0; };
}

/// Fetch a value and increment its access frequency. None if absent.
pub fn lfu_get(c: &mut LfuCache, key: Int) -> Option[Int] {
  var i = 0;
  while i < c.keys.len() {
    if c.keys[i] == key {
      c.counts[i] = c.counts[i] + 1;
      return Some(c.values[i]);
    }
    i = i + 1;
  }
  return None;
}

/// Insert or update a key. On overflow, evicts the lowest-frequency key
/// (tie-break: least recently inserted among the minimum-frequency group).
pub fn lfu_put(c: &mut LfuCache, key: Int, value: Int) {
  var i = 0;
  while i < c.keys.len() {
    if c.keys[i] == key {
      c.values[i] = value;
      c.counts[i] = c.counts[i] + 1;
      return;
    }
    i = i + 1;
  }
  if c.keys.len() >= c.capacity {
    var mi = 0;
    var j = 1;
    while j < c.keys.len() {
      if c.counts[j] < c.counts[mi] {
        mi = j;
      } elif c.counts[j] == c.counts[mi] {
        if c.seq[j] < c.seq[mi] {
          mi = j;
        }
      }
      j = j + 1;
    }
    c.keys.remove(mi);
    c.values.remove(mi);
    c.counts.remove(mi);
    c.seq.remove(mi);
  }
  c.keys.push(key);
  c.values.push(value);
  c.counts.push(1);
  c.seq.push(c.next_seq);
  c.next_seq = c.next_seq + 1;
}

/// True if the key is present in the cache.
pub fn lfu_contains(c: &LfuCache, key: Int) -> Bool {
  var i = 0;
  while i < c.keys.len() {
    if c.keys[i] == key { return true; }
    i = i + 1;
  }
  return false;
}

/// Number of entries currently cached.
pub fn lfu_size(c: &LfuCache) -> Int {
  return c.keys.len();
}
