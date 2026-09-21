// XIOM - Sync: Condvar
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.sync.condvar

// Depends on: xiom.sync

// ============================================================================
// Condition variable for waiting on a state change guarded by a mutex.
// Pure-XIOM data structure: the condition is a monotonic notify counter.
// `wait` records the current count, releases the paired mutex (from
// xiom.sync.mutex), polls the counter with 1 ms sleeps, then re-acquires
// the mutex. Any notify bumps the counter, so a notification issued before
// the wait is never lost (a prior notify makes `wait` return immediately).
//
// NOTE: the handle type is named `SyncCondvar` (the stub's `Condvar`) to
// avoid colliding with the parent module's same-named type.
// ============================================================================

use xiom.sync.mutex;

use xiom.alloc;
use xiom.ptr;

extern "C" {
  fn xiom_atomic_load(ptr: *Int) -> Int;
  fn xiom_atomic_fetch_add(ptr: *Int, val: Int) -> Int;
  fn xiom_thread_sleep_ms(ms: Int);
}

/// SyncCondvar (the stub's `Condvar`) - a condition variable paired with a mutex.
pub type SyncCondvar = { notified: *Int; }

/// Create a new condition variable.
/// Returns: a condvar with a zero notify count.
/// Complexity: O(1).
pub fn condvar_new() -> SyncCondvar {
  let s = alloc.alloc(8);
  unsafe { ptr.write(s as *Int, 0); }
  return SyncCondvar{ notified: s; }
}

/// Atomically release `m` and block until notified.
/// Params: cv - the condition variable; m - the mutex guarding the state.
/// Re-acquires `m` before returning.
/// Complexity: O(1) per poll; blocks until a notify.
pub fn condvar_wait(cv: SyncCondvar, m: SyncMutex) {
  var mm = m;
  mutex.mutex_unlock(&mut mm);
  var done = false;
  while !done {
    var n: Int;
    unsafe { n = xiom_atomic_load(cv.notified); }
    if n > 0 {
      unsafe { xiom_atomic_fetch_add(cv.notified, -1); }
      done = true;
    } else {
      unsafe { xiom_thread_sleep_ms(1); }
    }
  }
  mutex.mutex_lock(&mut mm);
}

/// Wait with a timeout; true if notified.
/// Params: cv - the condition variable; m - the mutex; ms - timeout in
///          milliseconds (clamped to >= 0).
/// Returns: true if notified before the timeout, false on timeout.
/// Re-acquires `m` before returning.
/// Complexity: O(ms) polls, each sleeping up to 1 ms.
pub fn condvar_wait_timeout(cv: SyncCondvar, m: SyncMutex, ms: Int) -> Bool {
  var mm = m;
  var budget = ms;
  if budget < 0 {
    budget = 0;
  }
  mutex.mutex_unlock(&mut mm);
  var notified = false;
  var i: Int = 0;
  var done = false;
  while !done {
    var n: Int;
    unsafe { n = xiom_atomic_load(cv.notified); }
    if n > 0 {
      unsafe { xiom_atomic_fetch_add(cv.notified, -1); }
      notified = true;
      done = true;
    } elif i >= budget {
      done = true;
    } else {
      unsafe { xiom_thread_sleep_ms(1); }
      i = i + 1;
    }
  }
  mutex.mutex_lock(&mut mm);
  return notified;
}

/// Wake one waiting thread.
/// Params: cv - the condition variable.
/// Complexity: O(1).
pub fn condvar_notify_one(cv: SyncCondvar)
  requires: cv.notified != null
{
  unsafe { xiom_atomic_fetch_add(cv.notified, 1); }
}

/// Wake all waiting threads.
/// Params: cv - the condition variable.
/// Complexity: O(1).
pub fn condvar_notify_all(cv: SyncCondvar)
  requires: cv.notified != null
{
  unsafe { xiom_atomic_fetch_add(cv.notified, 1); }
}
