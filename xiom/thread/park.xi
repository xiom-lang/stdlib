// XIOM - Thread: Park
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.thread.park

// Depends on: xiom.thread

// ============================================================================
// Thread parking: efficient blocking and explicit unparking by token.
// Pure-XIOM simulation over atomic flags. The thread-park slot is a single
// lazily-allocated atomic flag shared by the process (fine for the intended
// single-threaded simulation; the module-level Vec storage the runtime would
// need does not persist across calls in the current compiler). `unpark` flips
// the flag, so a prior unpark makes a later `park` return immediately.
// `ParkToken` is a standalone one-shot pair; waiters poll with 1 ms sleeps.
// ============================================================================

use xiom.thread.spawn;

use xiom.alloc;
use xiom.ptr;

extern "C" {
  fn xiom_atomic_load(ptr: *Int) -> Int;
  fn xiom_atomic_store(ptr: *Int, val: Int);
  fn xiom_thread_id() -> Int;
  fn xiom_thread_sleep_ms(ms: Int);
}

/// ParkToken - a standalone one-shot park/unpark pair not tied to a thread.
pub type ParkToken = { flag: *Int; }

var _park_flag: *Int = ptr.null[Int]();

/// Obtain the shared park flag, allocating it on first use.
fn park_get_flag() -> *Int {
  if ptr.is_null(_park_flag) {
    _park_flag = alloc.alloc(8);
    var p: *Int;
    unsafe { p = _park_flag as *Int; }
    unsafe { ptr.write(p, 0); }
  }
  return _park_flag;
}

/// Create a new park token.
/// Returns: a token with no pending notification.
/// Complexity: O(1).
pub fn park_token_new() -> ParkToken {
  let s = alloc.alloc(8);
  unsafe { ptr.write(s as *Int, 0); }
  return ParkToken{ flag: s; }
}

/// Block until the token is notified.
/// Params: tok - the token.
/// Complexity: O(1) per poll; blocks until a notify.
pub fn park_token_wait(tok: ParkToken) {
  var done = false;
  while !done {
    var f: Int;
    unsafe { f = xiom_atomic_load(tok.flag); }
    if f != 0 {
      unsafe { xiom_atomic_store(tok.flag, 0); }
      done = true;
    } else {
      unsafe { xiom_thread_sleep_ms(1); }
    }
  }
}

/// Release one waiter on the token.
/// Params: tok - the token.
/// Complexity: O(1).
pub fn park_token_notify(tok: ParkToken)
  requires: true
{
  unsafe { xiom_atomic_store(tok.flag, 1); }
}

/// Block the calling thread until it is unparked.
/// Complexity: O(1) per poll; blocks until an unpark.
pub fn park() {
  let flag = park_get_flag();
  var done = false;
  while !done {
    var f: Int;
    unsafe { f = xiom_atomic_load(flag); }
    if f != 0 {
      unsafe { xiom_atomic_store(flag, 0); }
      done = true;
    } else {
      unsafe { xiom_thread_sleep_ms(1); }
    }
  }
}

/// Block up to `ms` milliseconds; true if unparked first.
/// Params: ms - the timeout in milliseconds (clamped to >= 0).
/// Returns: true if unparked before the timeout, false on timeout.
/// Complexity: O(ms) polls, each sleeping up to 1 ms.
pub fn park_timeout(ms: Int) -> Bool {
  var budget = ms;
  if budget < 0 {
    budget = 0;
  }
  let flag = park_get_flag();
  var unparked = false;
  var i: Int = 0;
  var done = false;
  while !done {
    var f: Int;
    unsafe { f = xiom_atomic_load(flag); }
    if f != 0 {
      unsafe { xiom_atomic_store(flag, 0); }
      unparked = true;
      done = true;
    } elif i >= budget {
      done = true;
    } else {
      unsafe { xiom_thread_sleep_ms(1); }
      i = i + 1;
    }
  }
  return unparked;
}

/// Make the target thread eligible to resume.
/// Params: t - the target thread.
/// Complexity: O(1).
pub fn unpark(t: SpawnThread) {
  let flag = park_get_flag();
  unsafe { xiom_atomic_store(flag, 1); }
}

/// Unpark every thread in the vector.
/// Params: threads - the threads to wake.
/// Complexity: O(n) where n is the number of threads.
pub fn unpark_all(threads: &Vec[SpawnThread]) {
  let flag = park_get_flag();
  var i: Int = 0;
  var n = threads.len();
  while i < n {
    var t = threads[i];
    unsafe { xiom_atomic_store(flag, 1); }
    i = i + 1;
  }
}
