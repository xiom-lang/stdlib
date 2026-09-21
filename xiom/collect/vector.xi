// XIOM - Collections: Vector
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.vector

// Depends on: none

/// Growable array of Int elements with amortized O(1) push and O(1) indexed
/// access.
/// The backing store is the built-in Vec[Int]. NOTE: the API parameter type is
/// `IntVec` because defining a struct named `Vec` collides with the built-in
/// `Vec[T]` generic and silently corrupts codegen (compiler BUG 25 family);
/// the fn names and value signatures match the frozen spec exactly.
/// All index access is bounds-checked (Option-returning getters).
pub type IntVec = {
  items: Vec[Int];
}

/// Create a new empty vector. O(1).
pub fn vec_new() -> IntVec {
  return IntVec{ items: Vec[Int].new(); };
}

/// Append `value` to the end of the vector. Amortized O(1).
pub fn vec_push(v: &mut IntVec, value: Int) {
  v.items.push(value);
}

/// Remove and return the last value. None if the vector is empty. O(1).
pub fn vec_pop(v: &mut IntVec) -> Option[Int] {
  if v.items.len() == 0 { return None; }
  var o = v.items.pop();
  match o {
    Some(x) => { return Some(x); },
    None => { return None; },
  }
}

/// Number of elements currently stored. O(1).
pub fn vec_len(v: &IntVec) -> Int
  ensures: result >= 0
{
  var len = v.items.len();
  return len;
}

/// Value at index `idx`, or None when idx is out of bounds. O(1).
pub fn vec_get(v: &IntVec, idx: Int) -> Option[Int] {
  if idx < 0 || idx >= v.items.len() { return None; }
  return Some(v.items[idx]);
}

/// Overwrite the value at `idx`. Out-of-bounds indices are ignored. O(1).
pub fn vec_set(v: &mut IntVec, idx: Int, value: Int) {
  if idx < 0 || idx >= v.items.len() { return; }
  v.items[idx] = value;
}

/// Insert `value` at `idx`, shifting later elements right. Valid range is
/// 0..=len; other indices are ignored. O(n).
pub fn vec_insert(v: &mut IntVec, idx: Int, value: Int) {
  var len = v.items.len();
  if idx < 0 || idx > len { return; }
  v.items.push(0);
  var i = len;
  while i > idx {
    v.items[i] = v.items[i - 1];
    i = i - 1;
  }
  v.items[idx] = value;
}

/// Remove and return the value at `idx`, shifting later elements left.
/// None when idx is out of bounds. O(n).
pub fn vec_remove(v: &mut IntVec, idx: Int) -> Option[Int] {
  var len = v.items.len();
  if idx < 0 || idx >= len { return None; }
  var value = v.items[idx];
  var i = idx;
  while i + 1 < len {
    v.items[i] = v.items[i + 1];
    i = i + 1;
  }
  v.items.pop();
  return Some(value);
}

/// Remove all elements. O(1) (capacity is retained).
pub fn vec_clear(v: &mut IntVec)
  ensures: vec_len(v) == 0
{
  v.items.clear();
}

/// True if the vector holds no elements. O(1).
pub fn vec_is_empty(v: &IntVec) -> Bool
  ensures: result == (vec_len(v) == 0)
{
  return v.items.len() == 0;
}
