// XIOM - Collections: Fibonacci Heap
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.collect.fheap

// Depends on: none

// ============================================================================
// Fibonacci heap supporting amortized O(1) push, peek and decrease-key.
// Thin adapter over the production FibHeap in collect.heap for every function
// whose signature matches (new/push/pop/peek/len). fheap_merge and
// fheap_decrease_key are implemented here on top of the public FibHeap API.
// ============================================================================

use xiom.collect.heap;

/// Handle to a heap node, used by fheap_decrease_key. In the flat-arena
/// adaptation the handle wraps the node's arena index (nodes are allocated in
/// insertion order by fheap_push).
pub type FibNode = {
  idx: Int;
}

/// Create a new empty Fibonacci heap.
/// Returns: an empty FibHeap.
/// Complexity: O(1).
pub fn fheap_new() -> FibHeap {
  return fib_heap_new();
}

/// Insert an element.
/// Params: h - the heap; value - Int element to insert.
/// Complexity: O(1) amortized.
pub fn fheap_push(h: &mut FibHeap, value: Int) {
  fib_heap_insert(h, value);
}

/// Remove and return the minimum element. None if empty.
/// Params: h - the heap.
/// Returns: the minimum element, or None when empty.
/// Complexity: O(log n) amortized.
pub fn fheap_pop(h: &mut FibHeap) -> Option[Int] {
  return fib_heap_extract_min(h);
}

/// Peek at the minimum element. None if empty.
/// Params: h - the heap.
/// Returns: the minimum element without removing it, or None when empty.
/// Complexity: O(1).
pub fn fheap_peek(h: &FibHeap) -> Option[Int] {
  return fib_heap_find_min(h);
}

/// Merge `other` into this heap, leaving `other` empty.
/// Params: h - the receiving heap; other - the heap to consume.
/// Complexity: O(n log n) worst-case (drains via extract-min + insert).
pub fn fheap_merge(h: &mut FibHeap, other: &mut FibHeap) {
  while fib_heap_size(other) > 0 {
    var m = fib_heap_extract_min(other);
    match m {
      Some(v) => { fib_heap_insert(h, v); },
      None => {},
    }
  }
}

/// Decrease a node's key.
/// Params: h - the heap; node - a FibNode handle (arena index of a node
/// allocated by fheap_push); new_key - the smaller key.
/// Out-of-range handles and non-decreasing keys are ignored.
/// Complexity: O(1) amortized.
pub fn fheap_decrease_key(h: &mut FibHeap, node: &mut FibNode, new_key: Int) {
  var ok = fib_heap_decrease_key(h, node.idx, new_key);
}

/// Number of elements.
/// Params: h - the heap.
/// Returns: the number of elements currently stored.
/// Complexity: O(1).
pub fn fheap_len(h: &FibHeap) -> Int
  ensures: result >= 0
{
  return fib_heap_size(h);
}
