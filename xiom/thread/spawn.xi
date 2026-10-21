// XIOM - Thread: Spawn
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.thread.spawn

// Depends on: xiom.thread

use xiom.alloc;
use xiom.ptr;

// ============================================================================
// Real thread spawning, joining, detaching, and thread introspection.
// REAL since wave 145 (the runtime half shipped in v0.64.5): `spawn` runs
// the closure on a real OS thread through the spawn-with-result trampoline
// and `join` blocks until it exits. The wave-131 rule holds: the 8+8
// result buffer is allocated OUTSIDE the confined block, so it is
// main-heap memory the worker may write into and join may free.
// `spawn_with` (arg-carrying closures) STAYS INLINE -- the runtime's
// trampoline calls closures with no argument channel; a real arg-carrying
// spawn is queued behind the engine-6 arg freeze. `detach` releases the
// OS handle; the 16-byte result buffer of a detached thread is retained
// for the process lifetime (documented contract).
//
// NOTE: the handle type is named `SpawnThread` (the stub's `Thread`) to
// avoid colliding with the parent module's same-named type.
// ============================================================================

extern "C" {
  fn xiom_thread_id() -> Int;
  fn xiom_thread_sleep_ms(ms: Int);
  fn xiom_thread_yield();
  fn xiom_cpu_count() -> Int32;
  fn xiom_thread_spawn_with_result(fn_ptr: *UInt8, result_buf: *UInt8) -> *UInt8;
  fn xiom_thread_spawn_join(handle: *UInt8) -> Int;
  fn xiom_thread_spawn_detach(handle: *UInt8);
  fn xiom_thread_spawn_id(handle: *UInt8) -> Int;
}

var _spawn_ids: Int = 0;
var _main_thread_id: Int = -1;

/// SpawnThread (the stub's `Thread`) - a handle to a spawned thread.
pub type SpawnThread = { id: Int; handle: *UInt8; buf: *UInt8; }

fn next_thread_id() -> Int {
  _spawn_ids = _spawn_ids + 1;
  return _spawn_ids;
}

/// Start a new thread running `f` (REAL since wave 145).
/// Params: f - the function to run.
/// Returns: a handle to the thread; `join` waits for it, `detach` releases it.
/// Complexity: O(1) plus the cost of `f` on the worker.
pub fn spawn(f: fn()) -> SpawnThread
  ensures: result.id > 0
{
  // Wave 131 (REL-20261013-1423) + wave 145: allocate the 8+8 result
  // buffer OUTSIDE the confined block (main-heap memory), so the worker
  // trampoline may write the fixed 8-byte result and join may free it.
  let buf = alloc.alloc(16);
  unsafe {
    let done_ptr = buf as *Int;
    ptr.write(done_ptr, 0);
    let raw_fn = f as *UInt8;
    let handle = xiom_thread_spawn_with_result(raw_fn, buf);
    if handle == 0 {
      alloc.dealloc(buf, 16);
      return SpawnThread{ id: next_thread_id(); handle: 0 as *UInt8; buf: 0 as *UInt8; };
    }
    let id = xiom_thread_spawn_id(handle);
    return SpawnThread{ id: id; handle: handle; buf: buf; };
  }
}

/// Start a new thread running `f(arg)`.
/// Params: f - the function to run; arg - its single argument.
/// Returns: a handle to the (INLINE-run) closure -- spawn_with stays inline
/// until the runtime grows an argument channel (engine-6); the handle
/// carries no OS thread (join is a no-op Ok, detach a no-op).
/// Complexity: O(1) plus the cost of `f`.
pub fn spawn_with(f: fn(Int), arg: Int) -> SpawnThread
  ensures: result.id > 0
{
  f(arg);
  return SpawnThread{ id: next_thread_id(); handle: 0 as *UInt8; buf: 0 as *UInt8; };
}

/// Block until the thread exits; returns Ok(0). REAL since wave 145: waits
/// on the OS thread, then frees the result buffer. Inline handles (no OS
/// thread) join as a no-op Ok.
/// Params: t - the thread handle (consumed).
/// Complexity: O(1) syscall plus the worker's runtime.
pub fn join(t: SpawnThread) -> Result[Int, Str]
  ensures: true
{
  if t.handle == 0 {
    return Ok(0);
  }
  unsafe {
    let rc = xiom_thread_spawn_join(t.handle);
    if rc < 0 {
      return Err("spawn.join: join failed");
    }
  };
  alloc.dealloc(t.buf, 16);
  return Ok(0);
}

/// Let the thread run independently and free its OS handle. REAL since
/// wave 145: the runtime releases the handle on exit; the 16-byte result
/// buffer is retained for the process lifetime (documented). Inline
/// handles are a no-op.
/// Params: t - the thread handle (consumed).
/// Complexity: O(1).
pub fn detach(t: SpawnThread)
  requires: t.id > 0
{
  if t.handle == 0 {
    return;
  }
  unsafe { xiom_thread_spawn_detach(t.handle); }
}

/// Suspend the calling thread for `ms` milliseconds.
/// Params: ms - the sleep duration (clamped to >= 0).
/// Complexity: O(1) syscall.
pub fn sleep_ms(ms: Int) {
  var m = ms;
  if m < 0 {
    m = 0;
  }
  unsafe { xiom_thread_sleep_ms(m); }
}

/// Voluntarily give up the CPU timeslice.
/// Complexity: O(1) syscall.
pub fn yield_now()
  requires: true
{
  unsafe { xiom_thread_yield(); }
}

/// The id of the calling thread.
/// Returns: the OS thread id of the current thread.
/// Complexity: O(1).
pub fn thread_id() -> Int
  requires: true
{
  unsafe { return xiom_thread_id(); }
}

/// The number of running threads (hardware parallelism).
/// Returns: the available hardware thread count (>= 1).
/// Complexity: O(1).
pub fn thread_count() -> Int
  ensures: result >= 1
{
  let n: Int32 = unsafe { xiom_cpu_count() };
  if n < 1 {
    return 1;
  }
  return n as Int;
}

/// True if the calling thread is the main thread.
/// Returns: whether the current thread id matches the first-seen id.
/// Complexity: O(1).
pub fn is_main_thread() -> Bool {
  if _main_thread_id < 0 {
    _main_thread_id = unsafe { xiom_thread_id() };
  }
  let cur = unsafe { xiom_thread_id() };
  return cur == _main_thread_id;
}

/// Spawn a thread scoped to the current stack frame (real spawn + join).
/// Params: f - the function to run.
/// Returns: Ok(0) after the thread has run and been joined.
/// Complexity: O(1) plus the cost of `f` on the worker.
pub fn spawn_scoped(f: fn()) -> Result[Int, Str]
  ensures: true
{
  let t = spawn(f);
  return join(t);
}
