// XIOM - Collections: Multi-Producer Multi-Consumer Queue
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.mpmc

// Depends on: xiom.sync

// ============================================================================
// Bounded queue safe for multiple producers and multiple consumers.
// Ring buffer of `cap` slots with AtomicInt head/tail; producers reserve slots
// with fetch_add on `tail`, consumers claim them with fetch_add on `head`.
// push returns false when full, pop returns None when empty (non-blocking).
// ============================================================================

use xiom.sync;

pub type MpmcQueue = {
  buf: Vec[Int];
  cap: Int;
  head: AtomicInt;
  tail: AtomicInt;
}

/// Create a bounded MPMC queue with `capacity` slots.
/// Params: capacity - number of buffered slots (clamped to >= 1).
/// Returns: a queue able to hold up to `capacity` items.
/// Complexity: O(capacity) to pre-fill the ring.
pub fn mpmc_queue_new(capacity: Int) -> MpmcQueue {
  var cap = capacity;
  if cap < 1 { cap = 1; }
  var buf = Vec[Int].new();
  var i: Int = 0;
  while i < cap {
    buf.push(0);
    i = i + 1;
  }
  return MpmcQueue{ buf: buf; cap: cap; head: AtomicInt.new(0); tail: AtomicInt.new(0); };
}

/// Try to enqueue `value`. Fails (false) when the queue is full.
/// Params: q - the queue; value - item to enqueue.
/// Returns: true on success, false when full.
/// Complexity: O(1).
pub fn mpmc_push(q: &mut MpmcQueue, value: Int) -> Bool {
  var t = q.tail.fetch_add(1);
  var h = q.head.load();
  if t - h >= q.cap {
    q.tail.fetch_sub(1);
    return false;
  }
  q.buf[t % q.cap] = value;
  return true;
}

/// Try to dequeue a value. None when the queue is empty.
/// Params: q - the queue.
/// Returns: the oldest buffered item, or None when empty.
/// Complexity: O(1).
pub fn mpmc_pop(q: &mut MpmcQueue) -> Option[Int] {
  var h = q.head.fetch_add(1);
  var t = q.tail.load();
  if h >= t {
    q.head.fetch_sub(1);
    return Option[Int]{ is_some: false; value: 0; };
  }
  var v = q.buf[h % q.cap];
  return Option[Int]{ is_some: true; value: v; };
}

/// Number of buffered elements (approximate under concurrent access).
/// Params: q - the queue.
/// Returns: an approximation of the number of items currently buffered.
/// Complexity: O(1).
pub fn mpmc_size(q: &MpmcQueue) -> Int {
  var t = q.tail.load();
  var h = q.head.load();
  var n = t - h;
  if n < 0 { n = 0; }
  if n > q.cap { n = q.cap; }
  return n;
}
