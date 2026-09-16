// XIOM -- Threading
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.thread
use xiom.thread.pool;
use xiom.thread.spawn;
use xiom.thread.park;
use xiom.thread.local;

use xiom.alloc;
use xiom.ptr;
use xiom.core.size_of;  // bare intrinsic binding (strict catalog gate)

extern "C" {
  fn xiom_thread_create(fn_ptr: *UInt8, arg: *UInt8) -> *UInt8;
  fn xiom_thread_join(handle: *UInt8) -> Int32;
  fn xiom_thread_detach(handle: *UInt8);
  fn xiom_thread_self() -> *UInt8;
  fn xiom_thread_id() -> Int;
  fn xiom_thread_sleep_ms(ms: Int);
  fn xiom_thread_yield();
  fn xiom_cpu_count() -> Int32;
  fn xiom_thread_spawn(fn_ptr: *UInt8, arg: *UInt8) -> *UInt8;
  fn xiom_thread_spawn_join(handle: *UInt8) -> Int;
  fn xiom_thread_spawn_detach(handle: *UInt8);
  fn xiom_thread_spawn_id(handle: *UInt8) -> Int;
  fn xiom_thread_spawn_with_result(fn_ptr: *UInt8, result_buf: *UInt8) -> *UInt8;
}

pub type Thread = { handle: *UInt8; id: Int; }

pub type JoinHandle[T] = { thread: Thread; result_buf: *UInt8; }

pub fn spawn[T](f: fn() -> T) -> JoinHandle[T]
  requires: true
  ensures: result.thread.handle != 0 {
  unsafe {
    let bufsize = 8 + size_of[T]();
    let buf = alloc.alloc(bufsize);
    let done_ptr = buf as *Int;
    ptr.write(done_ptr, 0);
    let raw_fn = f as *UInt8;
    let handle = xiom_thread_spawn_with_result(raw_fn, buf);
    let id = xiom_thread_spawn_id(handle);
    let th = Thread{ handle: handle; id: id; };
    return JoinHandle[T]{ thread: th; result_buf: buf; };
  }
}

pub fn spawn_with_name[T](name: Str, f: fn() -> T) -> JoinHandle[T]
  requires: name.len() >= 0
{
  spawn[T](f)
}

pub fn JoinHandle.join[T](self) -> Result[T, Str]
  requires: self.thread.handle != 0
  ensures: true
{
  unsafe {
    let rc = xiom_thread_spawn_join(thread.handle);
    if rc < 0 {
      return Err("thread join failed");
    };
    let done_ptr = result_buf as *Int;
    let val_ptr = (result_buf + 8) as *T;
    let val = ptr.read(val_ptr);
    alloc.dealloc(result_buf, 8 + size_of[T]());
    return Ok(val);
  }
}

pub fn JoinHandle.is_finished[T](self) -> Bool
  requires: self.result_buf != 0
{
  unsafe {
    let done_ptr = result_buf as *Int;
    let done = ptr.read(done_ptr);
    return done != 0;
  }
}

pub fn JoinHandle.thread[T](self) -> Thread
  ensures: result.handle == self.thread.handle
{
  self.thread
}

pub fn JoinHandle.detach[T](self)
  requires: self.thread.handle != 0
  requires: self.result_buf != 0
{
  unsafe {
    xiom_thread_spawn_detach(thread.handle);
    alloc.dealloc(result_buf, 8 + size_of[T]());
  }
}

pub fn Thread.current() -> Thread
  requires: true
{
  unsafe {
    let handle = xiom_thread_self();
    let id = xiom_thread_id();
    return Thread{ handle: handle; id: id; }
  }
}

pub fn Thread.id(self) -> Int {
  self.id
}

pub fn Thread.name(self) -> Option[Str] {
  None
}

pub fn sleep_ms(ms: Int)
  requires: ms >= 0
{
  unsafe { xiom_thread_sleep_ms(ms); }
}

pub fn sleep(ms: Int) {
  sleep_ms(ms);
}

pub fn yield_now()
  requires: true
{
  unsafe { xiom_thread_yield(); }
}

// Scoped threads (borrows from parent scope)
pub type Scope = {}

pub fn scope[T](f: fn(&Scope) -> T) -> T {
  let s = Scope{};
  f(&s)
}

pub fn Scope.spawn[T](self, f: fn() -> T) -> JoinHandle[T] {
  spawn[T](f)
}

pub fn available_parallelism() -> Int
  requires: true
  ensures: result >= 1
{
  unsafe {
    let n = xiom_cpu_count();
    if n < 1 { return 1; };
    return n as Int;
  }
}

pub fn hardware_threads() -> Int {
  available_parallelism()
}

pub fn current_thread_id() -> Int
  requires: true
{
  unsafe { return xiom_thread_id(); }
}

// -- Thread Discovery -----------------------------------------------

/// Returns the number of available hardware threads.
/// Delegates to `available_parallelism()`.
/// Complexity: O(1). Thread-safe.
pub fn thread_count() -> Int {
  return available_parallelism();
}

// -- Sleep Helpers --------------------------------------------------

/// Sleeps for `us` microseconds, rounding down to the nearest millisecond.
/// Complexity: O(1) syscall. Thread-safe.
pub fn thread_sleep_us(us: Int) {
  sleep_ms(us / 1000);
}

/// Yields the current thread's time slice. Alias for `yield_now`.
/// Complexity: O(1) syscall. Thread-safe.
pub fn thread_yield() {
  yield_now();
}

// -- Parallel Iteration ---------------------------------------------

/// Executes `f(i)` for each `i` in [`start`, `end`).
/// NOTE: This is a SEQUENTIAL implementation. True parallel execution requires
/// spawning threads, which is not yet supported by this helper.
/// Complexity: O(end - start) sequential invocations.
pub fn thread_parallel_for(start: Int, end: Int, f: fn(Int)) {
  var i: Int = start;
  while i < end {
    f(i);
    i = i + 1;
  };
}

/// Returns the name of the current thread, or `None` if unnamed.
/// Delegates to `Thread.current().name`.
/// Complexity: O(1). Thread-safe.
pub fn thread_name_current() -> Option[Str] {
  return Thread.current().name();
}
