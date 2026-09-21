// XIOM - Collections: Adaptive Replacement Cache
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.arc

// Depends on: none

// ============================================================================
// Adaptive replacement cache (ARC) balancing recency and frequency for Int
// keys and values. Thin adapter over the production ArcCache in collect.cache:
// every signature matches, so all functions here delegate to it. See
// collect.cache for the T1/T2/B1/B2 list bookkeeping.
// ============================================================================

use xiom.collect.cache;

/// Create a new ARC cache holding at most `capacity` entries.
/// Params: capacity - maximum number of cached entries (clamped to >= 1).
/// Returns: an empty ArcCache.
/// Complexity: O(1).
pub fn arc_new(capacity: Int) -> ArcCache
  ensures: result.capacity >= 1
  ensures: result.p == 0
{
  return xiom.collect.cache.arc_new(capacity);
}

/// Get the value for a key, promoting it on a hit. None on a miss.
/// Params: c - the cache; key - Int key.
/// Returns: Some(value) if cached, None otherwise.
/// Complexity: O(n) (linear scan of the four lists).
pub fn arc_get(c: &mut ArcCache, key: Int) -> Option[Int]
  ensures: result.is_some == arc_contains(c, key)
{
  return xiom.collect.cache.arc_get(c, key);
}

/// Insert or update `key` -> `value`, adapting the cache to the workload.
/// Params: c - the cache; key - Int key; value - Int value.
/// Complexity: O(n) (linear scan of the four lists).
pub fn arc_put(c: &mut ArcCache, key: Int, value: Int)
  ensures: arc_contains(c, key)
{
  xiom.collect.cache.arc_put(c, key, value);
}

/// Check whether a key is present (does not change recency).
/// Params: c - the cache; key - Int key.
/// Returns: true if the key is cached.
/// Complexity: O(n) (linear scan of T1 and T2).
pub fn arc_contains(c: &mut ArcCache, key: Int) -> Bool
  ensures: result == true => arc_size(c) > 0
{
  return xiom.collect.cache.arc_contains(c, key);
}

/// Number of entries currently cached.
/// Params: c - the cache.
/// Returns: the number of cached key/value pairs.
/// Complexity: O(1).
pub fn arc_size(c: &mut ArcCache) -> Int
  ensures: result >= 0
{
  return xiom.collect.cache.arc_size(c);
}

/// Maximum number of entries the cache can hold.
/// Params: c - the cache.
/// Returns: the configured capacity.
/// Complexity: O(1).
pub fn arc_capacity(c: &mut ArcCache) -> Int
  ensures: result >= 0
{
  return xiom.collect.cache.arc_capacity(c);
}
