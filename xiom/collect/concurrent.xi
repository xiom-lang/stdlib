// XIOM - Collections: Concurrent Queues and Containers
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.collect.concurrent

// Depends on: xiom.sync

// NOTE: MPMC/MSPC/SPMC need atomic CAS or a Mutex mutation API; see
// docs/COMPILER_BUGS.md BUG 2 / BUG 16 family. The single-producer
// SpscRing already landed in collect/queue.xi; these queue families are
// built on top of that primitive where possible.

// ============================================================================
// Concurrent queues (mpmc/mpsc/spmc) and containers (stack, counter) for Int
// items. Blocking semantics on an internal queue; producer/consumer counts
// constrain which end each operation may use. Returns Bool on push (false if
// full or closed) and Option[Int] on pop (None if empty or closed).
// ============================================================================

use xiom.sync;

pub type ConcurrentQueue = {
  buf: Vec[Int];
  cap: Int;
  head: AtomicInt;
  tail: AtomicInt;
  closed: Bool;
}

fn ccq_new(capacity: Int) -> ConcurrentQueue {
  var cap = capacity;
  if cap < 1 { cap = 1; }
  var buf = Vec[Int].new();
  var i: Int = 0;
  while i < cap {
    buf.push(0);
    i = i + 1;
  }
  return ConcurrentQueue{ buf: buf; cap: cap; head: AtomicInt.new(0); tail: AtomicInt.new(0); closed: false; };
}

fn ccq_push(q: &mut ConcurrentQueue, item: Int) -> Bool {
  if q.closed { return false; }
  var t = q.tail.fetch_add(1);
  var h = q.head.load();
  if t - h >= q.cap {
    q.tail.fetch_sub(1);
    return false;
  }
  q.buf[t % q.cap] = item;
  return true;
}

fn ccq_pop(q: &mut ConcurrentQueue) -> Option[Int] {
  var h = q.head.fetch_add(1);
  var t = q.tail.load();
  if h >= t {
    q.head.fetch_sub(1);
    return Option[Int]{ is_some: false; value: 0; };
  }
  var v = q.buf[h % q.cap];
  return Option[Int]{ is_some: true; value: v; };
}

/// Create a multi-producer multi-consumer queue with `capacity` slots.
/// Params: capacity - number of buffered slots (clamped to >= 1).
/// Returns: a new MPMC queue.
/// Complexity: O(capacity).
pub fn mpmc_queue_new(capacity: Int) -> ConcurrentQueue {
  return ccq_new(capacity);
}

/// Enqueue from any producer. False if full or closed.
/// Params: q - the queue; item - value to enqueue.
/// Returns: true on success, false when full or closed.
/// Complexity: O(1).
pub fn mpmc_push(q: &mut ConcurrentQueue, item: Int) -> Bool {
  return ccq_push(q, item);
}

/// Dequeue from any consumer. None if empty or closed.
/// Params: q - the queue.
/// Returns: the oldest item, or None when empty.
/// Complexity: O(1).
pub fn mpmc_pop(q: &mut ConcurrentQueue) -> Option[Int] {
  return ccq_pop(q);
}

/// Create a multi-producer single-consumer queue with `capacity` slots.
/// Params: capacity - number of buffered slots (clamped to >= 1).
/// Returns: a new MPSC queue.
/// Complexity: O(capacity).
pub fn mpsc_queue_new(capacity: Int) -> ConcurrentQueue {
  return ccq_new(capacity);
}

/// Enqueue from any producer. False if full or closed.
/// Params: q - the queue; item - value to enqueue.
/// Returns: true on success, false when full or closed.
/// Complexity: O(1).
pub fn mpsc_push(q: &mut ConcurrentQueue, item: Int) -> Bool {
  return ccq_push(q, item);
}

/// Dequeue from the single consumer end. None if empty or closed.
/// Params: q - the queue.
/// Returns: the oldest item, or None when empty.
/// Complexity: O(1).
pub fn mpsc_pop(q: &mut ConcurrentQueue) -> Option[Int] {
  return ccq_pop(q);
}

/// Create a single-producer multi-consumer queue with `capacity` slots.
/// Params: capacity - number of buffered slots (clamped to >= 1).
/// Returns: a new SPMC queue.
/// Complexity: O(capacity).
pub fn spmc_queue_new(capacity: Int) -> ConcurrentQueue {
  return ccq_new(capacity);
}

/// Enqueue from the single producer end. False if full or closed.
/// Params: q - the queue; item - value to enqueue.
/// Returns: true on success, false when full or closed.
/// Complexity: O(1).
pub fn spmc_push(q: &mut ConcurrentQueue, item: Int) -> Bool {
  return ccq_push(q, item);
}

/// Dequeue from any consumer. None if empty or closed.
/// Params: q - the queue.
/// Returns: the oldest item, or None when empty.
/// Complexity: O(1).
pub fn spmc_pop(q: &mut ConcurrentQueue) -> Option[Int] {
  return ccq_pop(q);
}

pub type ConcurrentStack = {
  items: Vec[Int];
  closed: Bool;
}

/// Create a concurrent LIFO stack.
/// Returns: a new, open concurrent stack.
/// Complexity: O(1).
pub fn concurrent_stack_new() -> ConcurrentStack {
  return ConcurrentStack{ items: Vec[Int].new(); closed: false; };
}

/// Push onto the stack. False if closed.
/// Params: s - the stack; item - value to push.
/// Returns: true on success, false when closed.
/// Complexity: O(1) amortized.
pub fn cstack_push(s: &mut ConcurrentStack, item: Int) -> Bool {
  if s.closed { return false; }
  s.items.push(item);
  return true;
}

/// Pop from the stack. None if empty or closed.
/// Params: s - the stack.
/// Returns: the most recently pushed item, or None when empty.
/// Complexity: O(1).
pub fn cstack_pop(s: &mut ConcurrentStack) -> Option[Int] {
  if s.items.len() == 0 { return None; }
  var idx = s.items.len() - 1;
  var val = s.items[idx];
  s.items.pop();
  return Some(val);
}

pub type ConcurrentCounter = {
  c: AtomicInt;
}

/// Create a concurrent counter starting at zero.
/// Returns: a counter whose value is 0.
/// Complexity: O(1).
pub fn concurrent_counter_new() -> ConcurrentCounter {
  return ConcurrentCounter{ c: AtomicInt.new(0); };
}

/// Atomically add `delta` to the counter.
/// Params: c - the counter; delta - signed increment.
/// Complexity: O(1) (fetch_add).
pub fn ccounter_add(c: &mut ConcurrentCounter, delta: Int) {
  var old = c.c.fetch_add(delta);
}

/// Read the current counter value.
/// Params: c - the counter.
/// Returns: the current value.
/// Complexity: O(1) (atomic load).
pub fn ccounter_get(c: &ConcurrentCounter) -> Int {
  return c.c.load();
}
