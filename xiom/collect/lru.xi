// XIOM - Collections: LRU Cache (delegating shim)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// The canonical implementation lives in `xiom.collect.cache` (`LruCache`,
// `lru_*` and the LFU surface). This module keeps the historical
// `xiom.collect.lru` import path working by delegating every call, and keeps
// the original `&mut` receiver spellings so existing importers and the API
// snapshot see the same signatures.
//
// Duplication gate 2026-09-24: the duplicate `LruCache` declaration and the
// private `_lru_find`/`_lru_touch` helpers were removed; `lru_remove` and
// `lru_clear` were added to the canonical surface. The module can be deleted
// outright once consumers migrate and the compiler module lists are updated.

module xiom.collect.lru

use xiom.collect.cache;

/// Create a new LRU cache holding at most `capacity` entries.
/// Capacity is clamped to >= 1. O(1).
pub fn lru_new(capacity: Int) -> LruCache {
  return xiom.collect.cache.lru_new(capacity);
}

/// Get the value for `key`, marking it recently used. None if absent. O(n).
pub fn lru_get(c: &mut LruCache, key: Int) -> Option[Int] {
  return xiom.collect.cache.lru_get(c, key);
}

/// Insert or update `key` -> `value`, evicting the least-recently-used entry
/// when full. O(n).
pub fn lru_put(c: &mut LruCache, key: Int, value: Int) {
  xiom.collect.cache.lru_put(c, key, value);
}

/// Check whether `key` is present (does not change recency). O(n).
pub fn lru_contains(c: &mut LruCache, key: Int) -> Bool {
  return xiom.collect.cache.lru_contains(c, key);
}

/// Remove `key`, returning whether it was present. O(n).
pub fn lru_remove(c: &mut LruCache, key: Int) -> Bool {
  return xiom.collect.cache.lru_remove(c, key);
}

/// Number of entries currently cached. O(1).
pub fn lru_size(c: &mut LruCache) -> Int {
  return xiom.collect.cache.lru_size(c);
}

/// Maximum number of entries the cache can hold. O(1).
pub fn lru_capacity(c: &mut LruCache) -> Int {
  return xiom.collect.cache.lru_capacity(c);
}

/// Remove all entries from the cache. O(1).
pub fn lru_clear(c: &mut LruCache) {
  xiom.collect.cache.lru_clear(c);
}
