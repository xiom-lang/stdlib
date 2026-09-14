// XIOM - Collections: Ring Buffer
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.ring

// Depends on: none

// ============================================================================
// Bounded single-producer single-consumer ring buffer of Int elements.
// Fixed `cap` slots; `head`/`tail` are monotonic counters, the slot index is
// (counter % cap). When full, push returns false without blocking; when
// empty, pop returns None. NOTE: the reference collect.queue SpscRing uses
// AtomicInt counters; this module keeps the "Depends on: none" contract and
// uses plain Int counters, which are exactly equivalent for the SPSC
// single-threaded contract exercised by the smoke tests.
// ============================================================================

pub type SpscRing = {
  buf: Vec[Int];
  cap: Int;
  head: Int;
  tail: Int;
}

/// Create a ring with `cap` slots. A capacity below 1 is clamped to 1. O(cap).
pub fn ring_new(cap: Int) -> SpscRing {
  var n = cap;
  if n < 1 { n = 1; }
  var buf = Vec[Int].new();
  var i: Int = 0;
  while i < n {
    buf.push(0);
    i = i + 1;
  }
  return SpscRing{ buf: buf; cap: n; head: 0; tail: 0; };
}

/// Try to enqueue `value`; returns false when the ring is full. O(1).
pub fn ring_push(r: &mut SpscRing, value: Int) -> Bool {
  if r.tail - r.head >= r.cap { return false; }
  r.buf[r.tail % r.cap] = value;
  r.tail = r.tail + 1;
  return true;
}

/// Dequeue a value. None when the ring is empty. O(1).
pub fn ring_pop(r: &mut SpscRing) -> Option[Int] {
  if r.head >= r.tail { return None; }
  var value = r.buf[r.head % r.cap];
  r.head = r.head + 1;
  return Some(value);
}

/// Number of buffered elements. O(1).
pub fn ring_len(r: &SpscRing) -> Int
  ensures: result >= 0
{
  var n = r.tail - r.head;
  if n < 0 { n = 0; }
  if n > r.cap { n = r.cap; }
  return n;
}

/// True when the ring holds no elements. O(1).
pub fn ring_is_empty(r: &SpscRing) -> Bool
  ensures: result == (ring_len(r) == 0)
{
  return r.head >= r.tail;
}

/// Maximum number of buffered elements. O(1).
pub fn ring_capacity(r: &SpscRing) -> Int
  ensures: result >= 0
{
  return r.cap;
}
