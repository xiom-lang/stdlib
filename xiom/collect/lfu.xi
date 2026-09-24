// XIOM - Collections: LFU Cache (delegating shim)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// The canonical implementation lives in `xiom.collect.cache` (`LfuCache` and
// the `lfu_*` surface, including `lfu_remove`/`lfu_capacity`/`lfu_clear`).
// This module keeps the historical `xiom.collect.lfu` import path working by
// delegating every call, with the original receiver spellings.
//
// Duplication gate 2026-09-25: the duplicate `LfuCache` declaration and the
// private helpers were removed; the public function signatures are unchanged.
// NOTE for consumers: `xiom.collect.cache` also exports `lfu_*`, so a module
// importing both must alias one of them.

module xiom.collect.lfu

use xiom.collect.cache;

/// Create an LFU cache holding at most `capacity` entries.
pub fn lfu_new(capacity: Int) -> LfuCache
  ensures: result.keys.len() == 0
{
  return xiom.collect.cache.lfu_new(capacity);
}

/// Fetch a value and increment its access frequency. None if absent.
pub fn lfu_get(c: &mut LfuCache, key: Int) -> Option[Int]
  ensures: result.is_some == lfu_contains(c, key)
{
  return xiom.collect.cache.lfu_get(c, key);
}

/// Insert or update a key. On overflow, evicts the lowest-frequency key
/// (tie-break: least recently inserted among the minimum-frequency group).
pub fn lfu_put(c: &mut LfuCache, key: Int, value: Int)
  ensures: lfu_contains(c, key) == true
{
  xiom.collect.cache.lfu_put(c, key, value);
}

/// True if the key is present in the cache.
pub fn lfu_contains(c: &mut LfuCache, key: Int) -> Bool
  ensures: result == true => lfu_size(c) > 0
{
  return xiom.collect.cache.lfu_contains(c, key);
}

/// Remove `key`, returning whether it was present.
pub fn lfu_remove(c: &mut LfuCache, key: Int) -> Bool
  ensures: lfu_contains(c, key) == false
{
  return xiom.collect.cache.lfu_remove(c, key);
}

/// Number of entries currently cached.
pub fn lfu_size(c: &mut LfuCache) -> Int
  ensures: result >= 0
{
  return xiom.collect.cache.lfu_size(c);
}

/// Maximum number of entries the cache can hold.
pub fn lfu_capacity(c: &mut LfuCache) -> Int
  ensures: result >= 0
{
  return xiom.collect.cache.lfu_capacity(c);
}

/// Remove all entries from the cache.
pub fn lfu_clear(c: &mut LfuCache)
  ensures: lfu_size(c) == 0
{
  xiom.collect.cache.lfu_clear(c);
}
