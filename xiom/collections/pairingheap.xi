// XIOM - Collections: Pairing Heap
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.pairingheap

// Depends on: none (pure)

// ============================================================================
// Pairing heap (Int priorities) - a simple amortized O(log n) meldable heap.
// Supports push, pop-min, peek, size, merge and decrease-key in O(1) amortized
// for merge/meld operations. Ties are broken arbitrarily (min-heap semantics).
//
// Built on the production PHeap arena in collect.heap. push/pop/peek/size/
// is_empty delegate directly to it; pheap_merge drains one heap into the other
// through the public API, and pheap_decrease_key rewrites the arena after
// lowering the target node's key. Node handles are arena indices allocated in
// push order.
// ============================================================================

use xiom.collect.heap;

/// Create an empty pairing heap.
/// Returns: an empty PHeap-backed heap.
/// Complexity: O(1).
pub fn pheap_new() -> PHeap {
  return xiom.collect.heap.pheap_new();
}

/// Insert a priority.
/// Params: h - the heap; priority - Int priority to insert.
/// Complexity: O(log n) amortized.
pub fn pheap_push(h: &mut PHeap, priority: Int) {
  xiom.collect.heap.pheap_insert(h, priority);
}

/// Remove and return the minimum priority, or None if the heap is empty.
/// Params: h - the heap.
/// Returns: the minimum priority, or None when empty.
/// Complexity: O(log n) amortized.
pub fn pheap_pop(h: &mut PHeap) -> Option[Int] {
  return xiom.collect.heap.pheap_extract_min(h);
}

/// Return the minimum priority without removing it, or None if empty.
/// Params: h - the heap.
/// Returns: the minimum priority, or None when empty.
/// Complexity: O(1).
pub fn pheap_peek(h: &PHeap) -> Option[Int] {
  return xiom.collect.heap.pheap_find_min(h);
}

/// Number of priorities in the heap.
/// Params: h - the heap.
/// Returns: the number of reachable priorities.
/// Complexity: O(n) (reachable-node walk).
pub fn pheap_size(h: &PHeap) -> Int {
  return xiom.collect.heap.pheap_size(h);
}

/// Meld two heaps into one; `a` and `b` are consumed.
/// Params: a - the receiving heap; b - the heap to drain.
/// Returns: the merged heap (the same structure as `a`).
/// Complexity: O(n log n) (drains `b` via extract-min + insert).
pub fn pheap_merge(a: &mut PHeap, b: &mut PHeap) -> PHeap {
  while xiom.collect.heap.pheap_size(b) > 0 {
    var m = xiom.collect.heap.pheap_extract_min(b);
    match m {
      Some(v) => { xiom.collect.heap.pheap_insert(a, v); },
      None => {},
    }
  }
  return a;
}

/// Lower the priority of an existing node.
/// Params: h - the heap; node - arena index of a node allocated by pheap_push;
/// new_priority - the smaller priority.
/// Out-of-range handles and non-decreasing priorities are ignored. The arena
/// is rebuilt afterwards, so all node handles become stale.
/// Complexity: O(n log n) worst-case (full rebuild).
pub fn pheap_decrease_key(h: &mut PHeap, node: Int, new_priority: Int) {
  if node < 0 { return; }
  if node * 3 + 2 >= h.keys.len() { return; }
  var cur = h.keys[3 * node];
  if new_priority >= cur { return; }
  var collected = Vec[Int].new();
  if h.root != -1 {
    var stack = Vec[Int].new();
    stack.push(h.root);
    while stack.len() > 0 {
      var top_opt = stack.pop();
      match top_opt {
        Some(n) => {
          if n == node {
            collected.push(new_priority);
          } else {
            collected.push(h.keys[3 * n]);
          }
          var c = h.keys[3 * n + 1];
          while c != -1 {
            stack.push(c);
            c = h.keys[3 * c + 2];
          }
        },
        None => {},
      }
    }
  }
  var nh = xiom.collect.heap.pheap_new();
  var i = 0;
  while i < collected.len() {
    xiom.collect.heap.pheap_insert(&mut nh, collected[i]);
    i = i + 1;
  }
  h.root = nh.root;
  h.keys = nh.keys;
  h.children = nh.children;
}

/// True if the heap has no priorities.
/// Params: h - the heap.
/// Returns: true when the heap is empty.
/// Complexity: O(1).
pub fn pheap_is_empty(h: &PHeap) -> Bool {
  return xiom.collect.heap.pheap_is_empty(h);
}
