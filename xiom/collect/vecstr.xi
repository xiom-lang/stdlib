// XIOM - Collections: Vec[Str] helpers (contains / index-of / equality)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.vecstr

// Depends on: xiom.string (byte-exact str_compare for equality semantics),
// xiom.collections (vec_str_join delegation)

use xiom.string;
use xiom.collections;

// ============================================================================
// Vec[Str] helpers (packages wishlist row 38 `vec.str`): contains /
// index-of / element-wise equality / copy / order-preserving dedup / join.
// Requesters: locale, config; wave-50: terraform, chef, k8s.
//
// Equality is byte-exact (`str_compare == 0`), so results match the SipHash
// keying and the `xiom.string` byte order; no local `_streq` wrappers in
// consumer packages. Order-sensitive scans are O(N) with O(1) extra space.
// `vec_str_join` delegates to the canonical `xiom.collections.vec_str_join`.
// ============================================================================

/// True when any element equals `s` (byte-exact). O(N).
pub fn vec_str_contains(v: &Vec[Str], s: Str) -> Bool
  ensures: result == true => v.len() > 0
{
  var i = 0;
  while i < v.len() {
    if string.str_compare(v[i], s) == 0 { return true; }
    i = i + 1;
  }
  return false;
}

/// Index of the first element equal to `s`, or -1 when absent. O(N).
pub fn vec_str_index_of(v: &Vec[Str], s: Str) -> Int
  ensures: result >= -1
  ensures: result < v.len()
{
  var i = 0;
  while i < v.len() {
    if string.str_compare(v[i], s) == 0 { return i; }
    i = i + 1;
  }
  return -1;
}

/// Index of the last element equal to `s`, or -1 when absent. O(N).
pub fn vec_str_last_index_of(v: &Vec[Str], s: Str) -> Int
  ensures: result >= -1
  ensures: result < v.len()
{
  var i = v.len() - 1;
  while i >= 0 {
    if string.str_compare(v[i], s) == 0 { return i; }
    i = i - 1;
  }
  return -1;
}

/// Element-wise byte-exact equality; false when lengths differ. O(N).
pub fn vec_str_equal(a: &Vec[Str], b: &Vec[Str]) -> Bool
  ensures: a.len() != b.len() => result == false
  ensures: a.len() == 0 && b.len() == 0 => result == true
{
  if a.len() != b.len() { return false; }
  var i = 0;
  while i < a.len() {
    if string.str_compare(a[i], b[i]) != 0 { return false; }
    i = i + 1;
  }
  return true;
}

/// Copy a Vec[Str] into a fresh vector (independent length; element Str
/// values are copied by value). O(N).
pub fn vec_str_copy(v: &Vec[Str]) -> Vec[Str]
  ensures: result.len() == v.len()
{
  var out = Vec[Str].new();
  var i = 0;
  while i < v.len() {
    out.push(v[i]);
    i = i + 1;
  }
  return out;
}

/// First-occurrence-preserving dedup: keeps the first instance of each
/// distinct element in order. O(N^2) worst case (N = input length).
pub fn vec_str_unique(v: &Vec[Str]) -> Vec[Str]
  ensures: result.len() <= v.len()
{
  var out = Vec[Str].new();
  var i = 0;
  while i < v.len() {
    if !vec_str_contains(&out, v[i]) {
      out.push(v[i]);
    }
    i = i + 1;
  }
  return out;
}

/// Join with a separator (canonical implementation lives in
/// `xiom.collections`; exposed here so `use xiom.collect.vecstr;` alone is
/// enough for a Vec[Str] consumer). O(total length).
pub fn vec_str_join(items: &Vec[Str], sep: Str) -> Str
  ensures: items.len() == 0 => result.len() == 0
  ensures: items.len() == 1 => result == items[0]
{
  return collections.vec_str_join(items, sep);
}
