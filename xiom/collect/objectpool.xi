// XIOM -- Collections: Object pool (Int handles)
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.collect.objectpool

// ============================================================================
// ObjectPool (Int handles 0 .. capacity-1)
// `free` is a LIFO stack of released handles; `next` hands out fresh handles
// while below capacity. O(1) acquire/release; release validates the handle
// (double-release is rejected).
// ============================================================================

pub type ObjectPool = { free: Vec[Int]; next: Int; capacity: Int; }

/// Create a pool with `capacity` handles.
pub fn pool_new(capacity: Int) -> ObjectPool {
  var free = Vec[Int].new();
  return ObjectPool{ free: free; next: 0; capacity: capacity; };
}

/// Acquire a handle (None when the pool is exhausted).
pub fn pool_acquire(p: &mut ObjectPool) -> Option[Int] {
  if p.free.len() > 0 {
    var h = p.free[p.free.len() - 1];
    p.free.pop();
    return Option[Int]{ is_some: true; value: h; };
  }
  if p.next < p.capacity {
    var h2 = p.next;
    p.next = p.next + 1;
    return Option[Int]{ is_some: true; value: h2; };
  }
  return Option[Int]{ is_some: false; value: 0; };
}

/// Release a handle back to the pool. Returns false on out-of-range or
/// double-release.
pub fn pool_release(p: &mut ObjectPool, handle: Int) -> Bool {
  if handle < 0 || handle >= p.capacity {
    return false;
  }
  var i: Int = 0;
  while i < p.free.len() {
    if p.free[i] == handle {
      return false;
    }
    i = i + 1;
  }
  p.free.push(handle);
  return true;
}

/// Number of handles currently in use.
pub fn pool_in_use(p: &ObjectPool) -> Int
  ensures: result >= 0
{
  return p.next - p.free.len();
}

/// Number of handles available for acquire.
pub fn pool_available(p: &ObjectPool) -> Int
  ensures: result >= 0
{
  return p.capacity - p.next + p.free.len();
}

/// Total capacity.
pub fn pool_capacity(p: &ObjectPool) -> Int
  ensures: result >= 0
{
  return p.capacity;
}
