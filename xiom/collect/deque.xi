// XIOM - Collections: Deque
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.deque

// Depends on: none

// ============================================================================
// Double-ended queue of Int elements with O(1) push and pop at both ends.
// Backed by a single Vec[Int] with `head`/`tail` offsets defining the live
// window [head, tail). Pops advance the offsets (stale slots are later
// overwritten); `deque_push_front` rebuilds the window when there is no
// room at the front. All pops/peeks are bounds-checked (None on empty).
// ============================================================================

pub type Deque = {
  items: Vec[Int];
  head: Int;
  tail: Int;
}

/// Create an empty deque. O(1).
pub fn deque_new() -> Deque {
  return Deque{ items: Vec[Int].new(); head: 0; tail: 0; };
}

/// Append `value` to the back of the deque. O(1).
pub fn deque_push_back(d: &mut Deque, value: Int) {
  if d.tail < d.items.len() {
    d.items[d.tail] = value;
  } else {
    d.items.push(value);
  }
  d.tail = d.tail + 1;
}

/// Prepend `value` to the front of the deque. O(1) amortized (O(n) when the
/// window must be rebuilt).
pub fn deque_push_front(d: &mut Deque, value: Int) {
  if d.head > 0 {
    d.head = d.head - 1;
    d.items[d.head] = value;
    return;
  }
  var fresh = Vec[Int].new();
  fresh.push(value);
  var i = d.head;
  while i < d.tail {
    fresh.push(d.items[i]);
    i = i + 1;
  }
  d.items = fresh;
  d.head = 0;
  d.tail = fresh.len();
}

/// Remove and return the front value. None if the deque is empty. O(1).
pub fn deque_pop_front(d: &mut Deque) -> Option[Int] {
  if d.head >= d.tail { return None; }
  var value = d.items[d.head];
  d.head = d.head + 1;
  return Some(value);
}

/// Remove and return the back value. None if the deque is empty. O(1).
pub fn deque_pop_back(d: &mut Deque) -> Option[Int] {
  if d.head >= d.tail { return None; }
  d.tail = d.tail - 1;
  return Some(d.items[d.tail]);
}

/// Return the front value without removing it. None if empty. O(1).
pub fn deque_front(d: &Deque) -> Option[Int] {
  if d.head >= d.tail { return None; }
  return Some(d.items[d.head]);
}

/// Return the back value without removing it. None if empty. O(1).
pub fn deque_back(d: &Deque) -> Option[Int] {
  if d.head >= d.tail { return None; }
  var last = d.tail - 1;
  return Some(d.items[last]);
}

/// Number of elements in the deque. O(1).
pub fn deque_len(d: &Deque) -> Int {
  return d.tail - d.head;
}

/// True if the deque holds no elements. O(1).
pub fn deque_is_empty(d: &Deque) -> Bool {
  return d.head >= d.tail;
}
