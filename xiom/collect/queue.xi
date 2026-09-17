// XIOM -- Queue Collection (WorkQueue + Deque)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.queue

use xiom.sync;

// ============================================================================
// WorkQueue (Int items)
// A FIFO queue backed by a Vec plus a head offset. `push` appends at the end,
// `pop`/`peek` read from `head`. Popped entries are left in place (no
// compaction) so all operations stay O(1).
// ============================================================================

pub type WorkQueue = {
  items: Vec[Int];
  head: Int;
}

/// Create an empty work queue.
pub fn workqueue_new() -> WorkQueue
  ensures: result.head == 0
{
  return WorkQueue{ items: Vec[Int].new(); head: 0; };
}

/// Append an item to the back of the queue.
pub fn workqueue_push(q: &mut WorkQueue, item: Int) {
  q.items.push(item);
}

/// Remove and return the front item. None if empty.
pub fn workqueue_pop(q: &mut WorkQueue) -> Option[Int] {
  if q.head >= q.items.len() { return None; }
  var val = q.items[q.head];
  q.head = q.head + 1;
  return Some(val);
}

/// Return the front item without removing it. None if empty.
pub fn workqueue_peek(q: &WorkQueue) -> Option[Int]
  ensures: result.is_some == (workqueue_len(q) > 0)
{
  if q.head >= q.items.len() { return None; }
  return Some(q.items[q.head]);
}

/// Number of items currently in the queue.
pub fn workqueue_len(q: &WorkQueue) -> Int
  ensures: result >= 0
{
  return q.items.len() - q.head;
}

/// True if the queue contains no items.
pub fn workqueue_is_empty(q: &WorkQueue) -> Bool
  ensures: result == (workqueue_len(q) == 0)
{
  return q.head >= q.items.len();
}

// ============================================================================
// Deque (Int items)
// A double-ended queue backed by a Vec with `head`/`tail` offsets. Pushes
// append, pops advance the offsets. `deque_push_front` rebuilds the active
// range ([head, tail)) into a fresh Vec so no stale entries leak in.
// ============================================================================

pub type Deque = {
  items: Vec[Int];
  head: Int;
  tail: Int;
}

/// Create an empty deque.
pub fn deque_new() -> Deque
  ensures: result.head == 0 && result.tail == 0
{
  return Deque{ items: Vec[Int].new(); head: 0; tail: 0; };
}

/// Append an item to the back of the deque.
pub fn deque_push_back(d: &mut Deque, item: Int) {
  d.items.push(item);
  d.tail = d.items.len();
}

/// Prepend an item to the front of the deque.
pub fn deque_push_front(d: &mut Deque, item: Int) {
  var new_items = Vec[Int].new();
  new_items.push(item);
  var i = d.head;
  while i < d.tail {
    new_items.push(d.items[i]);
    i = i + 1;
  }
  d.items = new_items;
  d.head = 0;
  d.tail = new_items.len();
}

/// Remove and return the front item. None if empty.
pub fn deque_pop_front(d: &mut Deque) -> Option[Int] {
  if d.head >= d.tail { return None; }
  var val = d.items[d.head];
  d.head = d.head + 1;
  return Some(val);
}

/// Remove and return the back item. None if empty.
pub fn deque_pop_back(d: &mut Deque) -> Option[Int] {
  if d.head >= d.tail { return None; }
  d.tail = d.tail - 1;
  return Some(d.items[d.tail]);
}

/// Number of items currently in the deque.
pub fn deque_len(d: &Deque) -> Int
  ensures: result >= 0
{
  return d.tail - d.head;
}

/// True if the deque contains no items.
pub fn deque_is_empty(d: &Deque) -> Bool
  ensures: result == (deque_len(d) == 0)
{
  return d.head >= d.tail;
}

// ============================================================================
// SpscRing -- lock-free single-producer / single-consumer ring buffer
// (2026-08-11). Fixed `cap` slots (power of two not required; modulo via %).
// head = next slot to pop, tail = next slot to push, both AtomicInt
// (fetch_add based). Producer and consumer must each be used from exactly
// one thread. When full, push returns false without blocking; when empty,
// pop returns None. Slot reuse races are bounded by the documented usage
// contract (SPSC); a "full" or "empty" state read by the OTHER side may lag
// one operation, which is safe for SPSC.
// ============================================================================

pub type SpscRing = { buf: Vec[Int]; cap: Int; head: AtomicInt; tail: AtomicInt; }

/// Create an spsc ring with `cap` slots.
pub fn spsc_ring_new(cap: Int) -> SpscRing
  ensures: result.cap == cap
{
  var buf = Vec[Int].new();
  var i: Int = 0;
  while i < cap {
    buf.push(0);
    i = i + 1;
  }
  return SpscRing{ buf: buf; cap: cap; head: AtomicInt.new(0); tail: AtomicInt.new(0); };
}

/// Push `item` from the producer side. Returns false when the ring is full.
pub fn spsc_ring_push(r: &mut SpscRing, item: Int) -> Bool {
  var t = r.tail.fetch_add(1);
  var h = r.head.load();
  if t - h >= r.cap {
    r.tail.fetch_sub(1);
    return false;
  }
  r.buf[t % r.cap] = item;
  return true;
}

/// Pop an item from the consumer side. None when empty.
pub fn spsc_ring_pop(r: &mut SpscRing) -> Option[Int] {
  var h = r.head.fetch_add(1);
  var t = r.tail.load();
  if h >= t {
    r.head.fetch_sub(1);
    return Option[Int]{ is_some: false; value: 0; };
  }
  var v = r.buf[h % r.cap];
  return Option[Int]{ is_some: true; value: v; };
}

/// Number of items currently in the ring (approximate under concurrency).
pub fn spsc_ring_len(r: &SpscRing) -> Int
  ensures: result >= 0
{
  var t = r.tail.load();
  var h = r.head.load();
  var n = t - h;
  if n < 0 { n = 0; }
  if n > r.cap { n = r.cap; }
  return n;
}

/// True when the ring is empty (approximate under concurrency).
pub fn spsc_ring_is_empty(r: &SpscRing) -> Bool
  ensures: result == (spsc_ring_len(r) == 0)
{
  return r.tail.load() == r.head.load();
}

/// Capacity (number of slots).
pub fn spsc_ring_capacity(r: &SpscRing) -> Int
  ensures: result >= 0
{
  return r.cap;
}

