// XIOM - Collections: Work Queue
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.workqueue

// Depends on: none

/// FIFO queue of Int jobs consumed by worker threads.
/// Pure-XIOM data structure (no OS threads): a bounded-by-memory FIFO backed by
/// a flat Vec plus a head offset. push appends, pop reads from `head`; popped
/// slots are left in place (no compaction) so every operation is O(1).
pub type WorkQueue = {
  items: Vec[Int];
  head: Int;
}

/// Create a new empty work queue.
/// Returns: an empty WorkQueue with no pending jobs.
/// Complexity: O(1).
pub fn workqueue_new() -> WorkQueue {
  return WorkQueue{ items: Vec[Int].new(); head: 0; };
}

/// Append a job handle to the back of the queue.
/// Params: q - the queue; value - the Int job handle to enqueue.
/// Complexity: O(1) amortized.
pub fn workqueue_push(q: &mut WorkQueue, value: Int) {
  q.items.push(value);
}

/// Dequeue the front job handle. None when the queue is empty.
/// Params: q - the queue.
/// Returns: the oldest pending job, or None if no jobs are pending.
/// Complexity: O(1).
pub fn workqueue_pop(q: &mut WorkQueue) -> Option[Int] {
  if q.head >= q.items.len() { return None; }
  var val = q.items[q.head];
  q.head = q.head + 1;
  return Some(val);
}

/// Number of pending jobs.
/// Params: q - the queue.
/// Returns: the count of jobs not yet popped.
/// Complexity: O(1).
pub fn workqueue_len(q: &WorkQueue) -> Int
  ensures: result >= 0
{
  return q.items.len() - q.head;
}

/// True if no jobs are pending.
/// Params: q - the queue.
/// Returns: true when the queue holds no pending jobs.
/// Complexity: O(1).
pub fn workqueue_is_empty(q: &WorkQueue) -> Bool
  ensures: result == (workqueue_len(q) == 0)
{
  return q.head >= q.items.len();
}
