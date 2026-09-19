// XIOM - Collections: Blocking Queue
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.blockingqueue

// Depends on: xiom.sync

// ============================================================================
// Blocking queue (Int items) with a fixed capacity. Pure-XIOM data structure:
// there are no OS threads, so the blocking variants degrade to immediate
// returns (bq_push -> false when full, bq_pop -> None when empty) while
// keeping the same contract as a threaded implementation. bq_close wakes all
// waiters (a no-op here) and makes push fail while pop drains the remainder.
// ============================================================================

pub type BlockingQueue = {
  buf: Vec[Int];
  head: Int;
  capacity: Int;
  closed: Bool;
}

/// Create a blocking queue with `capacity` slots.
/// Params: capacity - maximum number of queued items (clamped to >= 1).
/// Returns: a new, open blocking queue.
/// Complexity: O(1).
pub fn blocking_queue_new(capacity: Int) -> BlockingQueue
  ensures: result.capacity >= 1
  ensures: result.closed == false
{
  var cap = capacity;
  if cap < 1 { cap = 1; }
  return BlockingQueue{ buf: Vec[Int].new(); head: 0; capacity: cap; closed: false; };
}

/// Enqueue `item`. Blocks while full in a threaded implementation; here it
/// returns false immediately when full or closed.
/// Params: q - the queue; item - value to enqueue.
/// Returns: true on success; false if the queue is full or closed.
/// Complexity: O(1) amortized.
pub fn bq_push(q: &mut BlockingQueue, item: Int) -> Bool
  ensures: result == true => bq_size(q) >= 1
{
  if q.closed { return false; }
  if q.buf.len() - q.head >= q.capacity { return false; }
  q.buf.push(item);
  return true;
}

/// Dequeue an item. Blocks while empty in a threaded implementation; here it
/// returns None immediately when empty or closed-and-drained.
/// Params: q - the queue.
/// Returns: the oldest item, or None when empty or closed and drained.
/// Complexity: O(1).
pub fn bq_pop(q: &mut BlockingQueue) -> Option[Int]
  ensures: result is None => bq_size(q) == 0
{
  if q.head >= q.buf.len() { return None; }
  var val = q.buf[q.head];
  q.head = q.head + 1;
  return Some(val);
}

/// Enqueue without blocking. Fails when full or closed.
/// Params: q - the queue; item - value to enqueue.
/// Returns: true on success; false if the queue is full or closed.
/// Complexity: O(1) amortized.
pub fn bq_try_push(q: &mut BlockingQueue, item: Int) -> Bool
  ensures: result == true => bq_size(q) >= 1
{
  if q.closed { return false; }
  if q.buf.len() - q.head >= q.capacity { return false; }
  q.buf.push(item);
  return true;
}

/// Dequeue without blocking. None when empty or closed.
/// Params: q - the queue.
/// Returns: the oldest item, or None when empty or closed and drained.
/// Complexity: O(1).
pub fn bq_try_pop(q: &mut BlockingQueue) -> Option[Int]
  ensures: result is None => bq_size(q) == 0
{
  if q.head >= q.buf.len() { return None; }
  var val = q.buf[q.head];
  q.head = q.head + 1;
  return Some(val);
}

/// Number of items currently queued.
/// Params: q - the queue.
/// Returns: the count of not-yet-popped items.
/// Complexity: O(1).
pub fn bq_size(q: &BlockingQueue) -> Int
  ensures: result >= 0
{
  return q.buf.len() - q.head;
}

/// Maximum number of items the queue can hold.
/// Params: q - the queue.
/// Returns: the fixed capacity.
/// Complexity: O(1).
pub fn bq_capacity(q: &BlockingQueue) -> Int
  ensures: result >= 0
{
  return q.capacity;
}

/// Close the queue: push fails afterwards, pop drains the remainder.
/// Params: q - the queue.
/// Complexity: O(1).
pub fn bq_close(q: &mut BlockingQueue)
  ensures: bq_is_closed(q)
{
  q.closed = true;
}

/// True if the queue has been closed.
/// Params: q - the queue.
/// Returns: whether bq_close has been called.
/// Complexity: O(1).
pub fn bq_is_closed(q: &BlockingQueue) -> Bool
  ensures: result == q.closed
{
  return q.closed;
}
