// XIOM - Collections: typed-Vec helpers (copy, pop ergonomics, truncation)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.vecops

// Depends on: none (built-in Vec only)

// ============================================================================
// Vec ergonomics on the collect face (packages wishlist rows 13, 21, 39):
//
//   * row 13 -- typed-vector copy helper: a fresh Vec with the same elements
//     in the same order. Requesters: exchanger, chaincrypto, actor, itest
//     (no `Vec.clone`). NOTE (wave 167): the copy family is CONCRETE per
//     element type, not `vec_copy[T]`: a generic copy instantiated for Int
//     and UInt8 in the same module reads back wrong UInt8 elements on the
//     v0.64.5 pin (scratch repro: Int copy first, then Vec[UInt8] copy
//     [7 as UInt8, 250 as UInt8] -> element 1 no longer compares equal;
//     the UInt8-first order is clean) -- a compiler-side monomorphization
//     finding, filed in the wave report. The concrete trio has the same
//     shape for every requested element type.
//   * row 21 -- pop ergonomics: element-returning `vec_pop_or` /
//     `vec_last_or` (no match needed) plus `vec_pop_checked`, the explicit
//     Option-shaped face of the built-in checked pop. Requesters: analyzer,
//     chaincore, formatter-fw.
//   * row 39 -- in-place truncation: `vec_truncate_to` (clamped resize-down;
//     the built-in `Vec.truncate` requires `new_len >= 0`) and
//     `vec_drop_last` (drop up to N tail elements, returning the count).
//     Requesters: formatter-fw, randomforest, parser-fw, jit-fw.
//
// Nothing here touches the built-in core Vec type: these are free helpers.
// ============================================================================

/// Copy a Vec[Int]: a fresh Vec holding the same elements in the same order.
/// O(N).
pub fn vec_copy_int(v: &Vec[Int]) -> Vec[Int]
  ensures: result.len() == v.len()
{
  var out = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    out.push(v[i]);
    i = i + 1;
  }
  return out;
}

/// Copy a Vec[Str]: a fresh Vec with the same elements (Str values copied by
/// value). O(N).
pub fn vec_copy_str(v: &Vec[Str]) -> Vec[Str]
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

/// Copy a Vec[UInt8]: a fresh Vec with the same bytes. O(N).
pub fn vec_copy_bytes(v: &Vec[UInt8]) -> Vec[UInt8]
  ensures: result.len() == v.len()
{
  var out = Vec[UInt8].new();
  var i = 0;
  while i < v.len() {
    out.push(v[i]);
    i = i + 1;
  }
  return out;
}

/// Pop the last element, or return `fallback` when the vector is empty.
/// Element-returning: no match at the call site. O(1).
pub fn vec_pop_or[T](v: &mut Vec[T], fallback: T) -> T
  ensures: v.len() == v.len()@pre - 1 || v.len() == v.len()@pre
{
  match v.pop() {
    Some(x) => { return x; },
    None => { return fallback; },
  }
}

/// Last element, or `fallback` when the vector is empty. O(1).
pub fn vec_last_or[T](v: &Vec[T], fallback: T) -> T
  ensures: v.len() == 0 => result == fallback
{
  var n = v.len();
  if n <= 0 { return fallback; }
  return v[n - 1];
}

/// Checked pop: the explicit Option-shaped face (None when empty, and the
/// element is removed only when Some). Delegates to the built-in checked
/// pop so the discipline is locked on the collect face too. O(1).
pub fn vec_pop_checked[T](v: &mut Vec[T]) -> Option[T]
  ensures: result is Some => v.len()@pre > 0
{
  return v.pop();
}

/// Truncate to at most `new_len` elements in place. Clamped: negative means
/// 0, values >= len leave the vector unchanged. O(1) (drops tail references).
pub fn vec_truncate_to[T](v: &mut Vec[T], new_len: Int)
  ensures: v.len() <= v.len()@pre
{
  if new_len < 0 {
    v.truncate(0);
    return;
  }
  if new_len >= v.len() { return; }
  v.truncate(new_len);
}

/// Drop up to `n` elements from the tail, returning how many were dropped.
/// `n <= 0` is a no-op. O(1) (drops tail references).
pub fn vec_drop_last[T](v: &mut Vec[T], n: Int) -> Int
  ensures: result >= 0
  ensures: v.len() == v.len()@pre - result
{
  if n <= 0 { return 0; }
  var k = n;
  if k > v.len() { k = v.len(); }
  v.truncate(v.len() - k);
  return k;
}
