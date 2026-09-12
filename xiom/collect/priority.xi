// XIOM - Collections: Priority Queue
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.priority

// Depends on: none

// ============================================================================
// Binary max-heap based priority queue of Int elements backed by the built-in
// Vec[Int]. `pqueue_pop` removes the largest element in O(log n); `pqueue_peek`
// inspects it in O(1). None on an empty queue.
// ============================================================================

pub type PHeap = {
  data: Vec[Int];
}

fn ph_swap(q: &mut PHeap, a: Int, b: Int) {
  var tmp = q.data[a];
  q.data[a] = q.data[b];
  q.data[b] = tmp;
}

fn ph_sift_up(q: &mut PHeap, i: Int) {
  var idx = i;
  while idx > 0 {
    var parent = (idx - 1) / 2;
    if q.data[idx] > q.data[parent] {
      ph_swap(q, idx, parent);
      idx = parent;
    } else {
      return;
    }
  }
}

fn ph_sift_down(q: &mut PHeap, i: Int) {
  var idx = i;
  var len = q.data.len();
  loop {
    var l = idx * 2 + 1;
    var r = idx * 2 + 2;
    var largest = idx;
    if l < len {
      if q.data[l] > q.data[largest] { largest = l; }
    }
    if r < len {
      if q.data[r] > q.data[largest] { largest = r; }
    }
    if largest == idx { return; }
    ph_swap(q, idx, largest);
    idx = largest;
  }
}

/// Create a new empty priority queue. O(1).
pub fn pqueue_new() -> PHeap {
  return PHeap{ data: Vec[Int].new(); };
}

/// Insert `value` into the queue. O(log n).
pub fn pqueue_push(q: &mut PHeap, value: Int) {
  q.data.push(value);
  var last = q.data.len() - 1;
  ph_sift_up(q, last);
}

/// Remove and return the highest-priority (largest) element. None if empty.
/// O(log n).
pub fn pqueue_pop(q: &mut PHeap) -> Option[Int] {
  if q.data.len() == 0 { return None; }
  var top = q.data[0];
  var last = q.data.len() - 1;
  q.data[0] = q.data[last];
  q.data.pop();
  if q.data.len() > 1 {
    ph_sift_down(q, 0);
  }
  return Some(top);
}

/// Return the highest-priority element without removing it. None if empty.
/// O(1).
pub fn pqueue_peek(q: &PHeap) -> Option[Int] {
  if q.data.len() == 0 { return None; }
  return Some(q.data[0]);
}

/// Number of elements in the queue. O(1).
pub fn pqueue_len(q: &PHeap) -> Int
  ensures: result >= 0
{
  var len = q.data.len();
  return len;
}

/// True if the queue holds no elements. O(1).
pub fn pqueue_is_empty(q: &PHeap) -> Bool
  ensures: result == (pqueue_len(q) == 0)
{
  return q.data.len() == 0;
}
