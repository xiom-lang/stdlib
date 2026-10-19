// p_async_executor_state.xi -- AsyncExecutor.run/block_on receiver state.
// Pre-existing bug: run() called self.step(), which mutated a copy, so
// external callers saw ex.ready still populated after run. The ready drain is
// now inlined; timers drain through fire_due_timers(&mut self).
// Expected rc 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_async_executor_state

use xiom.async;
use xiom.async.AsyncExecutor;

fn noop() {}

fn main() -> Int {
  var ex = AsyncExecutor.new();
  AsyncExecutor.spawn(&mut ex, noop);
  AsyncExecutor.spawn(&mut ex, noop);
  if ex.ready.len() != 2 { return 1; }
  AsyncExecutor.run(&mut ex);
  if ex.ready.len() != 0 { return 2; }

  var ex2 = AsyncExecutor.new();
  AsyncExecutor.at(&mut ex2, async_now_ms() - 1, noop);
  if ex2.timers.len() != 1 { return 3; }
  AsyncExecutor.run(&mut ex2);
  if ex2.timers.len() != 0 || ex2.ready.len() != 0 { return 4; }

  var ex3 = AsyncExecutor.new();
  AsyncExecutor.block_on(&mut ex3, noop);
  if ex3.ready.len() != 0 || ex3.timers.len() != 0 { return 5; }
  return 0;
}
