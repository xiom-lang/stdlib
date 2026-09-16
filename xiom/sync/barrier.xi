// XIOM - Sync: Barrier
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.sync.barrier

// Depends on: xiom.sync

// ============================================================================
// Reusable barrier that releases a fixed number of threads simultaneously.
// Pure-XIOM data structure over the xiom_atomic_* intrinsics: a guard
// spinlock protects the waiting counter, and a generation counter lets
// late arrivers distinguish the current cycle from the next one. The last
// arriver bumps the generation and releases every waiter.
//
// NOTE: the handle type is named `SyncBarrier` (the stub's `Barrier`) to
// avoid colliding with the parent module's same-named type.
// ============================================================================

use xiom.alloc;
use xiom.ptr;

extern "C" {
  fn xiom_atomic_load(ptr: *Int) -> Int;
  fn xiom_atomic_store(ptr: *Int, val: Int);
  fn xiom_atomic_fetch_add(ptr: *Int, val: Int) -> Int;
  fn xiom_atomic_exchange(ptr: *Int, val: Int) -> Int;
  fn xiom_thread_sleep_ms(ms: Int);
}

/// SyncBarrier (the stub's `Barrier`) - a reusable rendezvous for N threads.
pub type SyncBarrier = {
  guard: *Int;       // spinlock protecting the waiting counter
  count: Int;        // total threads
  waiting: *Int;     // atomic current waiters
  generation: *Int;  // atomic current generation
}

/// Acquire the internal guard spinlock.
fn barrier_lock_guard(b: &mut SyncBarrier) {
  let p: *Int = b.guard;
  var done = false;
  while !done {
    var old: Int;
    unsafe { old = xiom_atomic_exchange(p, 1); }
    if old == 0 {
      done = true;
    } else {
      unsafe { xiom_thread_sleep_ms(1); }
    }
  }
}

/// Release the internal guard spinlock.
fn barrier_unlock_guard(b: &mut SyncBarrier) {
  let p: *Int = b.guard;
  unsafe { xiom_atomic_store(p, 0); }
}

/// Create a barrier for `count` threads.
/// Params: count - the number of threads that must arrive to release.
/// Returns: a new barrier. A non-positive count is clamped to 1.
/// Complexity: O(1).
pub fn barrier_new(count: Int) -> SyncBarrier {
  var n = count;
  if n < 1 {
    n = 1;
  }
  let g = alloc.alloc(8);
  unsafe { ptr.write(g as *Int, 0); }
  let w = alloc.alloc(8);
  unsafe { ptr.write(w as *Int, 0); }
  let gen = alloc.alloc(8);
  unsafe { ptr.write(gen as *Int, 0); }
  return SyncBarrier{ guard: g; count: n; waiting: w; generation: gen; }
}

/// Block until all threads arrive; true for the last arriver.
/// Params: b - the barrier.
/// Returns: true when this call releases the barrier (the last arriver),
///          false for the other waiters.
/// Complexity: O(1) per poll; blocks until all threads arrive.
pub fn barrier_wait(b: &mut SyncBarrier) -> Bool {
  barrier_lock_guard(b);
  var gen: Int;
  unsafe { gen = xiom_atomic_load(b.generation); }
  var w: Int;
  unsafe { w = xiom_atomic_fetch_add(b.waiting, 1) + 1; }
  if w == b.count {
    let pw: *Int = b.waiting;
    let pg: *Int = b.generation;
    unsafe { xiom_atomic_store(pw, 0); }
    unsafe { xiom_atomic_fetch_add(pg, 1); }
    barrier_unlock_guard(b);
    return true;
  }
  barrier_unlock_guard(b);
  var cur_gen: Int;
  unsafe { cur_gen = xiom_atomic_load(b.generation); }
  while cur_gen == gen {
    unsafe { xiom_thread_sleep_ms(1); }
    unsafe { cur_gen = xiom_atomic_load(b.generation); }
  }
  return false;
}

/// The configured thread count.
/// Params: b - the barrier.
/// Returns: the number of threads the barrier was created for.
/// Complexity: O(1).
pub fn barrier_count(b: &SyncBarrier) -> Int
  ensures: result >= 1
{
  return b.count;
}

/// Reset the waiting counter to zero.
/// Params: b - the barrier.
/// Complexity: O(1). Not safe for concurrent use with active waiters.
pub fn barrier_reset(b: &mut SyncBarrier) {
  let pw: *Int = b.waiting;
  unsafe { xiom_atomic_store(pw, 0); }
}

/// True if every thread has arrived.
/// Params: b - the barrier.
/// Returns: whether the current cycle is complete (all threads arrived).
/// Complexity: O(1).
pub fn barrier_is_ready(b: &SyncBarrier) -> Bool {
  var w: Int;
  unsafe { w = xiom_atomic_load(b.waiting); }
  return w >= b.count;
}
