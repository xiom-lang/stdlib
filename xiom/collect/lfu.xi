// XIOM - Collections: LFU Cache
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.lfu

// Depends on: none

// ============================================================================
// Least-frequently-used cache with Int keys and values, evicting the least
// frequently accessed entry when full.
//
// Flat-arena style. `keys`/`values`/`counts` are parallel vectors; every
// access bumps the entry's frequency. `seq` is an insertion-sequence vector
// used as a deterministic tie-break: when several keys share the lowest
// frequency, the least recently inserted one is evicted first. `next_seq`
// hands out increasing sequence numbers. `lfu_get` / `lfu_put` increase the
// frequency of the touched key (a get on a hit counts as an access).
// ============================================================================

pub type LfuCache = {
  capacity: Int;
  keys: Vec[Int];
  values: Vec[Int];
  counts: Vec[Int];
  seq: Vec[Int];
  next_seq: Int;
}

/// Create a new LFU cache holding at most `capacity` entries.
/// Capacity is clamped to >= 1.
/// O(1).
pub fn lfu_new(capacity: Int) -> LfuCache {
  var cap = capacity;
  if cap < 1 {
    cap = 1;
  }
  return LfuCache{ capacity: cap; keys: Vec[Int].new(); values: Vec[Int].new(); counts: Vec[Int].new(); seq: Vec[Int].new(); next_seq: 0; };
}

/// Get the value for `key`, increasing its frequency. None if absent.
/// O(n).
pub fn lfu_get(c: &mut LfuCache, key: Int) -> Option[Int] {
  var i = 0;
  while i < c.keys.len() {
    if c.keys[i] == key {
      c.counts[i] = c.counts[i] + 1;
      return Option[Int]{ is_some: true; value: c.values[i]; };
    }
    i = i + 1;
  }
  return Option[Int]{ is_some: false; value: 0; };
}

/// Insert or update `key` -> `value`, evicting the least-frequently-used entry
/// when full (tie-break: least recently inserted among the minimum-frequency
/// group). A put on an existing key increases its frequency.
/// O(n).
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

/// Check whether `key` is present (does not change its frequency).
/// O(n).
pub fn lfu_contains(c: &mut LfuCache, key: Int) -> Bool {
  var i = 0;
  while i < c.keys.len() {
    if c.keys[i] == key {
      return true;
    }
    i = i + 1;
  }
  return false;
}

/// Remove `key`, returning whether it was present.
/// O(n).
pub fn lfu_remove(c: &mut LfuCache, key: Int) -> Bool {
  var i = 0;
  while i < c.keys.len() {
    if c.keys[i] == key {
      c.keys.remove(i);
      c.values.remove(i);
      c.counts.remove(i);
      c.seq.remove(i);
      return true;
    }
    i = i + 1;
  }
  return false;
}

/// Number of entries currently cached.
/// O(1).
pub fn lfu_size(c: &mut LfuCache) -> Int
  ensures: result >= 0
{
  return c.keys.len();
}

/// Maximum number of entries the cache can hold.
/// O(1).
pub fn lfu_capacity(c: &mut LfuCache) -> Int {
  return c.capacity;
}

/// Remove all entries from the cache.
/// O(1).
pub fn lfu_clear(c: &mut LfuCache)
  ensures: lfu_size(c) == 0
{
  while c.keys.len() > 0 {
    c.keys.pop();
    c.values.pop();
    c.counts.pop();
    c.seq.pop();
  }
  c.next_seq = 0;
}
