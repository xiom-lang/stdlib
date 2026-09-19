// XIOM - Collections: Hash Set
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.hashset

// Depends on: none

/// Hash set of unique Int elements using open addressing (linear probing) with
/// a power-of-two table. A parallel `used` flag vector allows every Int value
/// (including INT_MIN) as an element. The table doubles at 50% load. Hashes
/// are multiplicative and use shifts/multiplies plus a modulo index, so the
/// compiler's large-Int AND bug (BUG 25 #7) is avoided. `hashset_remove`
/// rebuilds the table (correct under tombstones; O(n) but simple and safe).
/// NOTE: the API parameter type is `HashSet`: naming it `Set` collides with
/// the `xiom.collections.Set[T]` generic and crashes the binary at startup
/// (0xC0000005); the fn names and value signatures match the frozen spec.
pub type HashSet = {
  slots: Vec[Int];
  used: Vec[Int];
  cap: Int;
  size: Int;
}

fn set_hash(v: Int, cap: Int) -> Int {
  var x = v * 0x9E3779B97F4A7C15;
  x = x ^ (x >> 33);
  x = x * 0xC2B2AE3D27D4EB4F;
  x = x ^ (x >> 29);
  var h = x % cap;
  if h < 0 { h = h + cap; }
  return h;
}

fn set_find(s: &HashSet, value: Int) -> Int {
  var i = set_hash(value, s.cap);
  var probes: Int = 0;
  while probes < s.cap {
    if s.used[i] == 0 { return -1; }
    if s.slots[i] == value { return i; }
    i = (i + 1) % s.cap;
    probes = probes + 1;
  }
  return -1;
}

fn set_place(s: &mut HashSet, value: Int) {
  var i = set_hash(value, s.cap);
  while s.used[i] == 1 {
    i = (i + 1) % s.cap;
  }
  s.slots[i] = value;
  s.used[i] = 1;
}

fn set_grow(s: &mut HashSet) {
  var old_slots = Vec[Int].new();
  var old_used = Vec[Int].new();
  var old_cap = s.cap;
  var i: Int = 0;
  while i < old_cap {
    old_slots.push(s.slots[i]);
    old_used.push(s.used[i]);
    i = i + 1;
  }
  var new_cap = old_cap * 2;
  s.slots = Vec[Int].new();
  s.used = Vec[Int].new();
  i = 0;
  while i < new_cap {
    s.slots.push(0);
    s.used.push(0);
    i = i + 1;
  }
  s.cap = new_cap;
  s.size = 0;
  i = 0;
  while i < old_cap {
    if old_used[i] == 1 {
      set_place(s, old_slots[i]);
      s.size = s.size + 1;
    }
    i = i + 1;
  }
}

/// Create a new empty hash set. O(1).
pub fn hashset_new() -> HashSet {
  var slots = Vec[Int].new();
  var used = Vec[Int].new();
  var i: Int = 0;
  while i < 16 {
    slots.push(0);
    used.push(0);
    i = i + 1;
  }
  return HashSet{ slots: slots; used: used; cap: 16; size: 0; };
}

/// Insert `value` if it is not already present. O(1) expected.
pub fn hashset_insert(s: &mut HashSet, value: Int) {
  if set_find(s, value) >= 0 { return; }
  if s.size * 2 >= s.cap {
    set_grow(s);
  }
  set_place(s, value);
  s.size = s.size + 1;
}

/// True if `value` is present. O(1) expected.
pub fn hashset_contains(s: &HashSet, value: Int) -> Bool {
  return set_find(s, value) >= 0;
}

/// Remove `value` if present. O(n) worst case (table rebuild).
pub fn hashset_remove(s: &mut HashSet, value: Int) {
  if set_find(s, value) < 0 { return; }
  var old_slots = Vec[Int].new();
  var old_used = Vec[Int].new();
  var old_cap = s.cap;
  var i: Int = 0;
  while i < old_cap {
    old_slots.push(s.slots[i]);
    old_used.push(s.used[i]);
    i = i + 1;
  }
  i = 0;
  while i < s.cap {
    s.used[i] = 0;
    i = i + 1;
  }
  s.size = 0;
  i = 0;
  while i < old_cap {
    if old_used[i] == 1 && old_slots[i] != value {
      set_place(s, old_slots[i]);
      s.size = s.size + 1;
    }
    i = i + 1;
  }
}

/// Number of elements in the set. O(1).
pub fn hashset_size(s: &HashSet) -> Int
  ensures: result >= 0
{
  return s.size;
}

/// Remove all elements. O(cap).
pub fn hashset_clear(s: &mut HashSet)
  ensures: hashset_size(s) == 0
{
  var i: Int = 0;
  while i < s.cap {
    s.used[i] = 0;
    i = i + 1;
  }
  s.size = 0;
}
