// XIOM - Collections: Insertion-Ordered Hash Map (delegating shim)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// The canonical implementation lives in `xiom.collect.hash` (`LhMap` and the
// `lhmap_*` functions). This module keeps the historical
// `xiom.collect.linkedhash` import path working by delegating every call.
//
// Duplication gate 2026-09-24: the duplicate `LhMap` declaration and the
// private `lhmap_find` helper were removed; the public function signatures
// are unchanged. The module can be deleted outright once consumers migrate
// to `xiom.collect.hash` and the compiler module lists are updated.

module xiom.collect.linkedhash

use xiom.collect.hash;

/// Create a new empty insertion-ordered map. O(1).
pub fn lhmap_new() -> LhMap
  ensures: result.keys.len() == 0
{
  return xiom.collect.hash.lhmap_new();
}

/// Insert or update `key` -> `value`. New keys are appended in insertion
/// order; updating keeps the existing position. O(n).
pub fn lhmap_put(m: &mut LhMap, key: Int, value: Int) {
  xiom.collect.hash.lhmap_put(m, key, value);
}

/// Value for `key`, or None when absent. O(n).
pub fn lhmap_get(m: &LhMap, key: Int) -> Option[Int] {
  return xiom.collect.hash.lhmap_get(m, key);
}

/// True if `key` is present. O(n).
pub fn lhmap_contains(m: &LhMap, key: Int) -> Bool {
  return xiom.collect.hash.lhmap_contains(m, key);
}

/// Remove `key` if present, preserving the relative order of the remaining
/// entries. O(n). Unit wrapper over the canonical Bool-returning function.
pub fn lhmap_remove(m: &mut LhMap, key: Int) {
  xiom.collect.hash.lhmap_remove(m, key);
}

/// Number of entries in the map. O(1).
pub fn lhmap_size(m: &LhMap) -> Int
  ensures: result >= 0
{
  return xiom.collect.hash.lhmap_size(m);
}

/// First key in insertion order, or None when the map is empty. O(1).
pub fn lhmap_first(m: &LhMap) -> Option[Int] {
  return xiom.collect.hash.lhmap_first(m);
}

/// Last key in insertion order, or None when the map is empty. O(1).
pub fn lhmap_last(m: &LhMap) -> Option[Int] {
  return xiom.collect.hash.lhmap_last(m);
}

/// All keys in insertion order. O(n).
pub fn lhmap_iter(m: &LhMap) -> Vec[Int] {
  return xiom.collect.hash.lhmap_iter(m);
}
