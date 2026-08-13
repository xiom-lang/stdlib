// XIOM - Sync: Mutex
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.sync.mutex

// Depends on: xiom.sync

// ============================================================================
// Blocking and try-lock mutual exclusion with lock-state introspection.
// Pure-XIOM test-and-set spinlock over the runtime xiom_atomic_* intrinsics
// (the runtime mutex FFI is not relied on here). `mutex_lock` spins on an
// atomic exchange until it claims the lock; `mutex_try_lock` performs a
// single non-blocking exchange. Correct across real threads; lock-state
// introspection reads the atomic owner flag.
//
// NOTE: the handle type is named `SyncMutex` (the stub's `Mutex`) to avoid
// colliding with the generic `Mutex[T]` type in the parent module, which the
// compiler mis-resolves for sub-module types of the same name.
// ============================================================================

use xiom.alloc;
use xiom.ptr;

extern "C" {
  fn xiom_atomic_load(ptr: *Int) -> Int;
  fn xiom_atomic_store(ptr: *Int, val: Int);
  fn xiom_atomic_exchange(ptr: *Int, val: Int) -> Int;
  fn xiom_thread_sleep_ms(ms: Int);
}

/// SyncMutex (the stub's `Mutex`) - an owned mutual exclusion primitive.
pub type SyncMutex = {
  locked: *Int;  // atomic 0/1 owner flag
}

/// Create a new unlocked mutex.
/// Returns: a mutex whose locked state is false.
/// Complexity: O(1).
pub fn mutex_new() -> SyncMutex {
  let s = alloc.alloc(8);
  unsafe { ptr.write(s as *Int, 0); }
  return SyncMutex{ locked: s; }
}

/// Block until the mutex is acquired.
/// Params: m - the mutex.
/// Complexity: O(1) per poll; spins with 1 ms sleeps while contended.
pub fn mutex_lock(m: &mut SyncMutex) {
  let p: *Int = m.locked;
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

/// Attempt a non-blocking acquire.
/// Params: m - the mutex.
/// Returns: true if the mutex was acquired, false if it is already held.
/// Complexity: O(1). Never blocks.
pub fn mutex_try_lock(m: &mut SyncMutex) -> Bool {
  let p: *Int = m.locked;
  var old: Int;
  unsafe { old = xiom_atomic_exchange(p, 1); }
  return old == 0;
}

/// Release a held mutex.
/// Params: m - the mutex.
/// Complexity: O(1).
pub fn mutex_unlock(m: &mut SyncMutex) {
  let p: *Int = m.locked;
  unsafe { xiom_atomic_store(p, 0); }
}

/// True if the mutex is currently held.
/// Params: m - the mutex.
/// Returns: whether the mutex is locked by any thread.
/// Complexity: O(1).
pub fn mutex_is_locked(m: &SyncMutex) -> Bool {
  let p: *Int = m.locked;
  var st: Int;
  unsafe { st = xiom_atomic_load(p); }
  return st != 0;
}

/// Consume the mutex and return the raw handle.
/// Params: m - the mutex (consumed).
/// Returns: the address of the atomic owner flag as an integer.
/// Complexity: O(1). Frees the flag storage.
pub fn mutex_into_inner(m: &mut SyncMutex) -> Int {
  let handle = m.locked as Int;
  unsafe { alloc.dealloc(m.locked as *UInt8, 8); }
  return handle;
}
