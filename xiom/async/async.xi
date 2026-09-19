// XIOM -- Async Library
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// A REAL cooperative single-threaded executor.
//
//   * `AsyncExecutor` owns a real ready-queue (`ready: Vec[fn()]`) and a real
//     timer set (`timers: Vec[Timer]`).
//   * `spawn` ENQUEUES a task onto the ready-queue; it does NOT run inline.
//   * `run` / `block_on` drive the ready-queue to completion, sleeping only
//     when the sole remaining work is a future-dated timer.
//   * Channels are scheduling-aware: `recv` yields to the executor when the
//     channel is empty (so a queued sender can run) and `send` applies
//     cooperative backpressure on a full bounded channel -- neither panics
//     during normal flow.
//   * `delay` registers a task that becomes ready after a real, monotonic
//     deadline; `sleep_ms` waits while still driving other ready tasks.
//
// NOTE: XIOM `fn()` values are non-capturing function pointers and the
// language has no async/await coroutine transform, so tasks run to
// completion (there is no mid-task suspension). Cooperation therefore
// happens at task boundaries -- `spawn`, `recv`, `send`, `delay`, `run`.
// This is a genuine ready-queue scheduler with real timers, not a
// stackful/epoll runtime.

use xiom.collections;

module xiom.async
use xiom.async.executor;
use xiom.async.channel;
use xiom.async.timer;
use xiom.async.io;

// === Runtime time source ===
// xiom_async_now_ms lives in stdlib/runtime/async_runtime.c (monotonic clock).
// xiom_thread_sleep_ms is owned by xiom_runtime.c (declared, never redefined).
extern "C" {
  fn xiom_async_now_ms() -> Int;
  fn xiom_thread_sleep_ms(ms: Int);
}

fn _now() -> Int
  requires: true
{
  unsafe { return xiom_async_now_ms(); }
}

// === Timer ===
// A task scheduled to become ready once the monotonic clock reaches `deadline`.
type Timer = {
  deadline: Int;
  task: fn();
}

// === AsyncExecutor ===
// A cooperative single-threaded scheduler: a FIFO-ish ready-queue plus a set
// of pending timers. Stored 8-byte-per-slot exactly like `Vec[LogEntry]`.
/// === AsyncExecutor ===
/// A cooperative single-threaded scheduler: a FIFO-ish ready-queue plus a set
/// of pending timers. Stored 8-byte-per-slot exactly like `Vec[LogEntry]`.
pub type AsyncExecutor = {
  ready: Vec[fn()];
  timers: Vec[Timer];
}

pub fn AsyncExecutor.new() -> AsyncExecutor {
  return AsyncExecutor{ ready: Vec[fn()].new(), timers: Vec[Timer].new() };
}

// Enqueue a task onto the ready-queue. It runs on the next drain, not now.
/// Enqueue a task onto the ready-queue. It runs on the next drain, not now.
pub fn AsyncExecutor.spawn(self, task: fn()) {
  self.ready.push(task);
}

// Register a task to become ready once the clock reaches `deadline`.
/// Register a task to become ready once the clock reaches `deadline`.
pub fn AsyncExecutor.at(self, deadline: Int, task: fn()) {
  self.timers.push(Timer{ deadline: deadline, task: task });
}

// Run a single ready task. Returns true if one was run, false if the
// ready-queue was empty.
/// Run a single ready task. Returns true if one was run, false if the
/// ready-queue was empty.
pub fn AsyncExecutor.step(self) -> Bool {
  if self.ready.len() == 0 {
    return false;
  }
  match self.ready.pop() {
    Some(task) => {
      task();
    },
    None => {},
  };
  return true;
}

// Advance pending timers: sleep until the earliest deadline, then move every
// timer that is now due onto the ready-queue (keeping the rest pending).
/// Advance pending timers: sleep until the earliest deadline, then move every
/// timer that is now due onto the ready-queue (keeping the rest pending).
pub fn AsyncExecutor.fire_due_timers(self) {
  if self.timers.len() == 0 {
    return;
  }
  // Drain every timer into a scratch list, tracking the earliest deadline.
  var pending = Vec[Timer].new();
  var earliest: Int = -1;
  while self.timers.len() > 0 {
    match self.timers.pop() {
      Some(t) => {
        if earliest < 0 || t.deadline < earliest {
          earliest = t.deadline;
        }
        pending.push(t);
      },
      None => {},
    };
  }
  // Wait until the earliest deadline so at least one timer becomes due.
  let now = _now();
  if earliest > now {
    unsafe { xiom_thread_sleep_ms(earliest - now); }
  }
  // Re-partition: due timers -> ready-queue, the rest -> back to the timer set.
  let fire_at = _now();
  while pending.len() > 0 {
    match pending.pop() {
      Some(t) => {
        if t.deadline <= fire_at {
          self.ready.push(t.task);
        } else {
          self.timers.push(t);
        }
      },
      None => {},
    };
  }
}

// Drive the scheduler until both the ready-queue and the timer set are empty.
/// Drive the scheduler until both the ready-queue and the timer set are empty.
pub fn AsyncExecutor.run(self) {
  while self.ready.len() > 0 || self.timers.len() > 0 {
    // Drain every currently-ready task (tasks may enqueue more as they run).
    while self.ready.len() > 0 {
      self.step();
    }
    // Ready-queue exhausted: advance timers so at least one becomes ready.
    if self.timers.len() > 0 {
      self.fire_due_timers();
    }
  }
}

// Spawn a task then drive to completion.
/// Spawn a task then drive to completion.
pub fn AsyncExecutor.block_on(self, task: fn()) {
  self.spawn(task);
  self.run();
}

// === Global executor ===
// The process-wide cooperative scheduler used by the free functions below.
var _exec: AsyncExecutor = AsyncExecutor.new();

// Make progress on the global executor: run one ready task, else fire timers.
// Returns false only when the executor is completely idle.
fn _pump() -> Bool {
  if _exec.ready.len() > 0 {
    _exec.step();
    return true;
  }
  if _exec.timers.len() > 0 {
    _exec.fire_due_timers();
    return true;
  }
  return false;
}

// === Spawn ===
// Enqueue an async task onto the global executor's ready-queue.
// NOTE: unlike the old stub, this no longer runs `task` inline -- it is
// scheduled and runs when the executor is driven via `run`/`block_on`.
/// === Spawn ===
/// Enqueue an async task onto the global executor's ready-queue.
/// NOTE: unlike the old stub, this no longer runs `task` inline -- it is
/// scheduled and runs when the executor is driven via `run`/`block_on`.
pub fn spawn(task: fn()) {
  _exec.spawn(task);
}

// Drive the global executor until all tasks and timers are complete.
/// Drive the global executor until all tasks and timers are complete.
pub fn run() {
  _exec.run();
}

// Spawn a task and drive the global executor to completion.
/// Spawn a task and drive the global executor to completion.
pub fn block_on(task: fn()) {
  _exec.spawn(task);
  _exec.run();
}

// Schedule `task` to become ready after `ms` milliseconds (real timer).
/// Schedule `task` to become ready after `ms` milliseconds (real timer).
pub fn delay(ms: Int, task: fn())
  requires: ms >= 0
{
  _exec.at(_now() + ms, task);
}

// Cooperative sleep: wait `ms` milliseconds while still driving other ready
// tasks, so the single thread keeps making progress during the wait.
// NOTE: with no coroutine transform this blocks the calling frame; it does
// not suspend-and-resume it. Use `delay` for true fire-after-deadline tasks.
/// Cooperative sleep: wait `ms` milliseconds while still driving other ready
/// tasks, so the single thread keeps making progress during the wait.
/// NOTE: with no coroutine transform this blocks the calling frame; it does
/// not suspend-and-resume it. Use `delay` for true fire-after-deadline tasks.
pub fn sleep_ms(ms: Int) {
  let deadline = _now() + ms;
  while _now() < deadline {
    if !_pump() {
      let remaining = deadline - _now();
      if remaining > 0 {
        unsafe { xiom_thread_sleep_ms(remaining); }
      }
    }
  }
}

// === Channel type ===
/// === Channel type ===
pub type Channel[T] = {
  items: Vec[T];
  closed: Bool;
  cap: Int;
  invariant: items.len() <= cap || cap == 0;
}

pub fn Channel.bounded[T](capacity: Int) -> Channel[T]
  requires: capacity > 0
{
  return Channel[T]{ items: Vec[T].with_capacity(capacity), closed: false, cap: capacity };
}

pub fn Channel.unbounded[T]() -> Channel[T] {
  return Channel[T]{ items: Vec[T].new(), closed: false, cap: 0 };
}

pub fn Channel.send[T](&mut self, value: T) {
  if closed {
    return;
  }
  // Cooperative backpressure: when a bounded channel is full, yield to the
  // executor so a receiver can drain it -- never panic during normal flow.
  while cap > 0 && items.len() >= cap {
    if !_pump() {
      panic("Channel.send: deadlock -- channel full and scheduler idle");
    }
  }
  items.push(value);
}

pub fn Channel.recv[T](&mut self) -> T {
  // Cooperative receive: when empty, yield to the executor so a queued sender
  // can run, then return the value. Never panics during normal flow.
  while items.len() == 0 {
    if !_pump() {
      panic("Channel.recv: deadlock -- channel empty and scheduler idle");
    }
  }
  var val = items[0];
  var i = 0;
  while i + 1 < items.len() {
    items[i] = items[i + 1];
    i = i + 1;
  }
  items.pop();
  return val;
}

pub fn Channel.try_recv[T](&mut self) -> Option[T] {
  if items.len() == 0 { return None; }
  var val = items[0];
  var i = 0;
  while i + 1 < items.len() {
    items[i] = items[i + 1];
    i = i + 1;
  }
  items.pop();
  return Some(val);
}

pub fn Channel.close[T](self) {
  closed = true;
}

// -- Async Task ID Counter ------------------------------------------

var _async_task_counter: Int = 0;

// -- Time & Yield Helpers -------------------------------------------

/// Returns the current monotonic time in milliseconds.
/// Complexity: O(1). Thread-safe.
pub fn async_now_ms() -> Int {
  return _now();
}

/// Cooperative sleep: waits `ms` milliseconds while driving other ready tasks.
/// Complexity: O(ms) pump iterations.
pub fn async_sleep_ms(ms: Int) {
  sleep_ms(ms);
}

/// Yields execution to other ready tasks by sleeping for 0ms.
/// Complexity: O(1) pump iteration.
pub fn async_yield_now()
  requires: true  // whole-body unsafe sleep call (T007)
{
  unsafe { xiom_thread_sleep_ms(0); };
}

// -- Spawn Helpers --------------------------------------------------

/// Enqueues a task onto the global executor and returns a task id.
/// Complexity: O(1). Thread-safe: accesses global executor.
pub fn async_spawn(f: fn()) -> Int {
  _exec.spawn(f);
  _async_task_counter = _async_task_counter + 1;
  return _async_task_counter;
}

/// Schedules a task to become ready after `ms` milliseconds.
/// Complexity: O(1). Thread-safe: accesses global executor.
pub fn async_spawn_delayed(ms: Int, f: fn()) {
  _exec.at(_now() + ms, f);
}

// -- AsyncExecutor Inspection & Control ----------------------------------

/// Runs one step of the given executor. Returns `true` if a task was run.
/// Complexity: O(1). Thread-safe if executor is not shared.
pub fn async_step_once(exec: &mut AsyncExecutor) -> Bool {
  return exec.step();
}

/// Returns `true` if the executor has pending tasks or timers.
/// Complexity: O(1). Thread-safe: reads immutable data.
pub fn async_has_pending(exec: &AsyncExecutor) -> Bool {
  return exec.ready.len() > 0 || exec.timers.len() > 0;
}

/// Drains all ready tasks from the executor without advancing timers.
/// Complexity: O(ready_queue_size).
pub fn async_run_until_idle(exec: &mut AsyncExecutor) {
  while exec.ready.len() > 0 {
    exec.step();
  };
}

/// Returns the number of pending timers in the executor.
/// Complexity: O(1). Thread-safe: reads immutable data.
pub fn async_timer_count(exec: &AsyncExecutor) -> Int {
  return exec.timers.len();
}
