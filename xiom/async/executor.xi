// XIOM - Async: Executor
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.async.executor

// Depends on: xiom.async

// ============================================================================
// Cooperative single-threaded task executor and the block_on entry point.
// Self-contained implementation: a FIFO ready-queue of `fn()` tasks plus a
// set of deadline timers. `executor_run` drains ready tasks and, when the
// queue is empty, sleeps until the earliest timer deadline before firing due
// timers. `block_on` drives a fresh local executor to completion.
//
// NOTE: the timer handle type is named `TaskTimer` (matching the private
// `Timer` shape in the parent module, which must not be re-declared).
// ============================================================================

extern "C" {
  fn xiom_async_now_ms() -> Int;
  fn xiom_thread_sleep_ms(ms: Int);
}

/// TaskTimer - a task scheduled to become ready at a deadline.
pub type TaskTimer = {
  deadline: Int;
  task: fn();
}

/// Executor - a scheduler owning a ready queue of tasks and pending timers.
pub type Executor = {
  ready: Vec[fn()];
  timers: Vec[TaskTimer];
}

/// Create an empty executor.
/// Returns: an executor with no ready tasks and no timers.
/// Complexity: O(1).
pub fn executor_new() -> Executor {
  return Executor{ ready: Vec[fn()].new(); timers: Vec[TaskTimer].new(); }
}

/// Enqueue a task to run on the next drain.
/// Params: e - the executor; f - the task.
/// Complexity: O(1) amortized.
pub fn executor_spawn(e: &mut Executor, f: fn()) {
  e.ready.push(f);
}

/// Schedule a blocking task outside the executor thread.
/// Params: e - the executor; f - the task.
/// In this cooperative simulation the task joins the ready queue directly.
/// Complexity: O(1) amortized.
pub fn executor_spawn_blocking(e: &mut Executor, f: fn()) {
  e.ready.push(f);
}

/// Run one ready task; true if one ran.
fn executor_step(e: &mut Executor) -> Bool {
  if e.ready.len() == 0 {
    return false;
  }
  match e.ready.pop() {
    Some(task) => {
      task();
    },
    None => {},
  }
  return true;
}

/// Advance pending timers: sleep until the earliest deadline, then move every
/// timer that is now due onto the ready-queue.
fn executor_fire_due_timers(e: &mut Executor) {
  if e.timers.len() == 0 {
    return;
  }
  var pending: Vec[TaskTimer] = Vec[TaskTimer].new();
  var earliest: Int = -1;
  while e.timers.len() > 0 {
    match e.timers.pop() {
      Some(t) => {
        if earliest < 0 || t.deadline < earliest {
          earliest = t.deadline;
        }
        pending.push(t);
      },
      None => {},
    }
  }
  let now = unsafe { xiom_async_now_ms() };
  if earliest > now {
    unsafe { xiom_thread_sleep_ms(earliest - now); }
  }
  let fire_at = unsafe { xiom_async_now_ms() };
  while pending.len() > 0 {
    match pending.pop() {
      Some(t) => {
        if t.deadline <= fire_at {
          e.ready.push(t.task);
        } else {
          e.timers.push(t);
        }
      },
      None => {},
    }
  }
}

/// Drive the executor until the queues are empty.
/// Params: e - the executor.
/// Complexity: O(tasks) executions plus timer sleeps.
pub fn executor_run(e: &mut Executor) {
  while e.ready.len() > 0 || e.timers.len() > 0 {
    var drained = true;
    while e.ready.len() > 0 {
      executor_step(e);
      drained = false;
    }
    if drained && e.timers.len() > 0 {
      executor_fire_due_timers(e);
    }
  }
}

/// Drain currently ready tasks without advancing timers.
/// Params: e - the executor.
/// Complexity: O(tasks).
pub fn executor_run_until_idle(e: &mut Executor) {
  while e.ready.len() > 0 {
    executor_step(e);
  }
}

/// Stop accepting tasks and release executor resources.
/// Params: e - the executor.
/// Complexity: O(tasks + timers).
pub fn executor_shutdown(e: &mut Executor) {
  while e.ready.len() > 0 {
    e.ready.pop();
  }
  while e.timers.len() > 0 {
    e.timers.pop();
  }
}

/// The number of queued tasks and timers.
/// Params: e - the executor.
/// Returns: ready tasks plus pending timers.
/// Complexity: O(1).
pub fn executor_tasks(e: &Executor) -> Int {
  return e.ready.len() + e.timers.len();
}

/// Spawn `f` and drive a fresh global-style executor to completion.
/// Params: f - the task.
/// Returns: Ok(0) once `f` and any spawned work complete.
/// Complexity: O(tasks) executions.
pub fn block_on(f: fn()) -> Result[Int, Str] {
  var exec = executor_new();
  executor_spawn(&mut exec, f);
  executor_run(&mut exec);
  return Ok(0);
}
