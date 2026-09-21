// XIOM - Collections: Dense Set
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.dense

// Depends on: none

/// Dense set of unique Int elements backed by a bitmap for compact storage.
/// 
/// Non-negative values are stored as a single bit each; the bitmap lives in a
/// `Vec[UInt8]` (value v occupies bit v % 8 of byte v / 8) that grows on demand
/// to cover the largest inserted value. All core operations are O(1); iteration
/// is O(bits) plus the set size. Negative values cannot be represented and are
/// rejected by `dense_add` (documented, no silent failure).
pub type DenseSet = {
  bits: Vec[UInt8];
  size: Int;
}

fn _contains_at(s: &DenseSet, value: Int) -> Bool {
  if value < 0 {
    return false;
  }
  var byte_idx = value / 8;
  if byte_idx >= s.bits.len() {
    return false;
  }
  var bit_idx = value % 8;
  var cur = s.bits[byte_idx] as Int;
  return (cur & (1 << bit_idx)) != 0;
}

fn _grow(s: &mut DenseSet, upto_byte: Int) {
  while s.bits.len() <= upto_byte {
    s.bits.push((0) as UInt8);
  }
}

/// Create a new empty dense set.
/// O(1).
pub fn dense_set_new() -> DenseSet {
  return DenseSet{ bits: Vec[UInt8].new(); size: 0; };
}

/// Add a value to the set (no-op if already present). Negative values are
/// rejected (the bitmap cannot represent them).
/// O(1) amortized.
pub fn dense_add(s: &mut DenseSet, value: Int) {
  if value < 0 {
    return;
  }
  var byte_idx = value / 8;
  var bit_idx = value % 8;
  _grow(s, byte_idx);
  var cur = s.bits[byte_idx] as Int;
  if (cur & (1 << bit_idx)) != 0 {
    return;
  }
  cur = cur | (1 << bit_idx);
  s.bits[byte_idx] = cur as UInt8;
  s.size = s.size + 1;
}

/// Check whether a value is present.
/// O(1).
pub fn dense_contains(s: &DenseSet, value: Int) -> Bool {
  return _contains_at(s, value);
}

/// Remove a value from the set (no-op if absent).
/// O(1).
pub fn dense_remove(s: &mut DenseSet, value: Int) {
  if !_contains_at(s, value) {
    return;
  }
  var byte_idx = value / 8;
  var bit_idx = value % 8;
  var cur = s.bits[byte_idx] as Int;
  cur = cur & ~(1 << bit_idx);
  s.bits[byte_idx] = cur as UInt8;
  s.size = s.size - 1;
}

/// Number of elements in the set.
/// O(1).
pub fn dense_size(s: &DenseSet) -> Int
  ensures: result >= 0
{
  return s.size;
}

/// Iterate all elements in ascending order.
/// O(bits + n).
pub fn dense_iter(s: &DenseSet) -> Vec[Int] {
  var out = Vec[Int].new();
  var b = 0;
  while b < s.bits.len() {
    var cur = s.bits[b] as Int;
    var bit = 0;
    while bit < 8 {
      if (cur & (1 << bit)) != 0 {
        out.push(b * 8 + bit);
      }
      bit = bit + 1;
    }
    b = b + 1;
  }
  return out;
}
