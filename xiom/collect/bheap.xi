// XIOM - Collections: Binary Heap
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.bheap

// Depends on: none

// ============================================================================
// Classic binary heap of Int elements. Thin adapter over the production
// pairing heap in collect.heap: PHeap satisfies the binary-heap contract
// (push, pop-min, peek, len) with the same signatures, so every function here
// delegates to it. See collect.heap for the flat-arena layout.
// ============================================================================

use xiom.collect.heap;

/// Create a new empty binary heap.
/// Returns: an empty PHeap-backed heap.
/// Complexity: O(1).
pub fn bheap_new() -> PHeap {
  return pheap_new();
}

/// Insert an element.
/// Params: h - the heap; value - Int element to insert.
/// Complexity: O(log n) amortized.
pub fn bheap_push(h: &mut PHeap, value: Int) {
  pheap_insert(h, value);
}

/// Remove and return the top (minimum) element. None if empty.
/// Params: h - the heap.
/// Returns: the minimum element, or None when the heap is empty.
/// Complexity: O(log n) amortized.
pub fn bheap_pop(h: &mut PHeap) -> Option[Int] {
  return pheap_extract_min(h);
}

/// Peek at the top (minimum) element. None if empty.
/// Params: h - the heap.
/// Returns: the minimum element without removing it, or None when empty.
/// Complexity: O(1).
pub fn bheap_peek(h: &PHeap) -> Option[Int] {
  return pheap_find_min(h);
}

/// Number of elements.
/// Params: h - the heap.
/// Returns: the number of elements currently stored.
/// Complexity: O(n) (reachable-node walk).
pub fn bheap_len(h: &PHeap) -> Int
  ensures: result >= 0
{
  return pheap_size(h);
}
