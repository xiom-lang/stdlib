// XIOM - Thread: Spawn
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.thread.spawn

// Depends on: xiom.thread

// ============================================================================
// Raw thread spawning, joining, detaching, and thread introspection.
// SIMULATION: the current toolchain cannot start real OS threads (fn-to-
// pointer casts are rejected and the runtime thread entrypoint AVs), so
// `spawn`/`spawn_with` execute the closure INLINE and return a synthetic
// handle; `join` reports success immediately. `sleep_ms`, `yield_now`,
// `thread_id`, `thread_count`, and `is_main_thread` use the real runtime
// intrinsics. Documented per the threadpool-module simulation contract.
//
// NOTE: the handle type is named `SpawnThread` (the stub's `Thread`) to
// avoid colliding with the parent module's same-named type.
// ============================================================================

extern "C" {
  fn xiom_thread_id() -> Int;
  fn xiom_thread_sleep_ms(ms: Int);
  fn xiom_thread_yield();
  fn xiom_cpu_count() -> Int32;
}

var _spawn_ids: Int = 0;
var _main_thread_id: Int = -1;

/// SpawnThread (the stub's `Thread`) - a handle to a (simulated) thread.
pub type SpawnThread = { id: Int; }

fn next_thread_id() -> Int {
  _spawn_ids = _spawn_ids + 1;
  return _spawn_ids;
}

/// Start a new thread running `f`.
/// Params: f - the function to run.
/// Returns: a handle to the thread. The closure runs inline (simulation).
/// Complexity: O(1) plus the cost of `f`.
pub fn spawn(f: fn()) -> SpawnThread {
  f();
  return SpawnThread{ id: next_thread_id(); }
}

/// Start a new thread running `f(arg)`.
/// Params: f - the function to run; arg - its single argument.
/// Returns: a handle to the thread. The closure runs inline (simulation).
/// Complexity: O(1) plus the cost of `f`.
pub fn spawn_with(f: fn(Int), arg: Int) -> SpawnThread {
  f(arg);
  return SpawnThread{ id: next_thread_id(); }
}

/// Block until the thread exits; returns its exit code.
/// Params: t - the thread handle (consumed).
/// Returns: Ok(0); the simulated thread has already completed.
/// Complexity: O(1).
pub fn join(t: SpawnThread) -> Result[Int, Str] {
  return Ok(0);
}

/// Let the thread run independently and free its resources on exit.
/// Params: t - the thread handle (consumed).
/// Complexity: O(1).
pub fn detach(t: SpawnThread) {
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
pub fn yield_now() {
  unsafe { xiom_thread_yield(); }
}

/// The id of the calling thread.
/// Returns: the OS thread id of the current thread.
/// Complexity: O(1).
pub fn thread_id() -> Int {
  unsafe { return xiom_thread_id(); }
}

/// The number of running threads (hardware parallelism).
/// Returns: the available hardware thread count (>= 1).
/// Complexity: O(1).
pub fn thread_count() -> Int {
  let n = unsafe { xiom_cpu_count() };
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

/// Spawn a thread scoped to the current stack frame (spawn + join).
/// Params: f - the function to run.
/// Returns: Ok(0) after the closure runs inline (simulation).
/// Complexity: O(1) plus the cost of `f`.
pub fn spawn_scoped(f: fn()) -> Result[Int, Str] {
  f();
  return Ok(0);
}
