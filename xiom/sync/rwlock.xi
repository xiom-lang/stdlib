// XIOM - Sync: RwLock
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.sync.rwlock

// Depends on: xiom.sync

// ============================================================================
// Reader-writer lock allowing concurrent readers or one exclusive writer.
// Pure-XIOM data structure over the xiom_atomic_* intrinsics. The lock
// tracks an active-reader count and a writer flag in two separate atomic
// cells (all values non-negative; the runtime atomic store does not round
// trip negative Ints). A guard spinlock serialises state transitions.
// Writers wait while readers or a writer are active; readers wait while a
// writer is active; both poll with 1 ms sleeps.
//
// NOTE: the handle type is named `SyncRwLock` (the stub's `RwLock`) to
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

/// SyncRwLock (the stub's `RwLock`) - a reader-writer lock protecting shared data.
pub type SyncRwLock = {
  guard: *Int;   // spinlock guarding state transitions
  readers: *Int; // atomic active-reader count (>= 0)
  writer: *Int;  // atomic writer flag (0 or 1)
}

/// Acquire the internal guard spinlock.
fn rwlock_lock_guard(l: &mut SyncRwLock) {
  let p: *Int = l.guard;
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
fn rwlock_unlock_guard(l: &mut SyncRwLock) {
  let p: *Int = l.guard;
  unsafe { xiom_atomic_store(p, 0); }
}

/// Create an unlocked reader-writer lock.
/// Returns: a new lock with no readers and no writer.
/// Complexity: O(1).
pub fn rwlock_new() -> SyncRwLock {
  let g = alloc.alloc(8);
  unsafe { ptr.write(g as *Int, 0); }
  let r = alloc.alloc(8);
  unsafe { ptr.write(r as *Int, 0); }
  let w = alloc.alloc(8);
  unsafe { ptr.write(w as *Int, 0); }
  return SyncRwLock{ guard: g; readers: r; writer: w; }
}

/// Acquire a shared read lock, blocking for writers.
/// Params: l - the lock.
/// Complexity: O(1) per poll; blocks while a writer holds the lock.
pub fn rwlock_read_lock(l: &mut SyncRwLock) {
  var done = false;
  while !done {
    rwlock_lock_guard(l);
    var w: Int;
    unsafe { w = xiom_atomic_load(l.writer); }
    if w == 0 {
      unsafe { xiom_atomic_fetch_add(l.readers, 1); }
      rwlock_unlock_guard(l);
      done = true;
    } else {
      rwlock_unlock_guard(l);
      unsafe { xiom_thread_sleep_ms(1); }
    }
  }
}

/// Acquire a read lock without blocking.
/// Params: l - the lock.
/// Returns: true if the read lock was acquired, false if a writer holds it.
/// Complexity: O(1). Never blocks.
pub fn rwlock_read_try_lock(l: &mut SyncRwLock) -> Bool {
  rwlock_lock_guard(l);
  var w: Int;
  unsafe { w = xiom_atomic_load(l.writer); }
  if w != 0 {
    rwlock_unlock_guard(l);
    return false;
  }
  unsafe { xiom_atomic_fetch_add(l.readers, 1); }
  rwlock_unlock_guard(l);
  return true;
}

/// Release a held read lock.
/// Params: l - the lock.
/// Complexity: O(1).
pub fn rwlock_read_unlock(l: &mut SyncRwLock) {
  rwlock_lock_guard(l);
  var r: Int;
  unsafe { r = xiom_atomic_load(l.readers); }
  if r > 0 {
    unsafe { xiom_atomic_fetch_add(l.readers, -1); }
  }
  rwlock_unlock_guard(l);
}

/// Acquire the exclusive write lock, blocking.
/// Params: l - the lock.
/// Complexity: O(1) per poll; blocks while readers are active.
pub fn rwlock_write_lock(l: &mut SyncRwLock) {
  var done = false;
  while !done {
    rwlock_lock_guard(l);
    var r: Int;
    var w: Int;
    unsafe { r = xiom_atomic_load(l.readers); }
    unsafe { w = xiom_atomic_load(l.writer); }
    if r == 0 && w == 0 {
      unsafe { xiom_atomic_store(l.writer, 1); }
      rwlock_unlock_guard(l);
      done = true;
    } else {
      rwlock_unlock_guard(l);
      unsafe { xiom_thread_sleep_ms(1); }
    }
  }
}

/// Acquire the write lock without blocking.
/// Params: l - the lock.
/// Returns: true if the write lock was acquired, false if the lock is held.
/// Complexity: O(1). Never blocks.
pub fn rwlock_write_try_lock(l: &mut SyncRwLock) -> Bool {
  rwlock_lock_guard(l);
  var r: Int;
  var w: Int;
  unsafe { r = xiom_atomic_load(l.readers); }
  unsafe { w = xiom_atomic_load(l.writer); }
  if r != 0 || w != 0 {
    rwlock_unlock_guard(l);
    return false;
  }
  unsafe { xiom_atomic_store(l.writer, 1); }
  rwlock_unlock_guard(l);
  return true;
}

/// Release a held write lock.
/// Params: l - the lock.
/// Complexity: O(1).
pub fn rwlock_write_unlock(l: &mut SyncRwLock) {
  rwlock_lock_guard(l);
  unsafe { xiom_atomic_store(l.writer, 0); }
  rwlock_unlock_guard(l);
}

/// True if the lock is held for writing.
/// Params: l - the lock.
/// Returns: whether a writer currently holds the lock.
/// Complexity: O(1).
pub fn rwlock_is_write_locked(l: &SyncRwLock) -> Bool {
  var w: Int;
  unsafe { w = xiom_atomic_load(l.writer); }
  return w != 0;
}

/// Consume the lock and return the raw handle.
/// Params: l - the lock (consumed).
/// Returns: the address of the writer cell as an integer.
/// Complexity: O(1). Frees the state storage.
pub fn rwlock_into_inner(l: &mut SyncRwLock) -> Int {
  let handle = l.writer as Int;
  unsafe { alloc.dealloc(l.guard as *UInt8, 8); }
  unsafe { alloc.dealloc(l.readers as *UInt8, 8); }
  unsafe { alloc.dealloc(l.writer as *UInt8, 8); }
  return handle;
}
