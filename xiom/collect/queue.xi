// XIOM — Queue Collection (WorkQueue + Deque)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.queue

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
pub fn workqueue_new() -> WorkQueue {
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
pub fn workqueue_peek(q: &WorkQueue) -> Option[Int] {
  if q.head >= q.items.len() { return None; }
  return Some(q.items[q.head]);
}

/// Number of items currently in the queue.
pub fn workqueue_len(q: &WorkQueue) -> Int {
  return q.items.len() - q.head;
}

/// True if the queue contains no items.
pub fn workqueue_is_empty(q: &WorkQueue) -> Bool {
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
pub fn deque_new() -> Deque {
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
pub fn deque_len(d: &Deque) -> Int {
  return d.tail - d.head;
}

/// True if the deque contains no items.
pub fn deque_is_empty(d: &Deque) -> Bool {
  return d.head >= d.tail;
}
