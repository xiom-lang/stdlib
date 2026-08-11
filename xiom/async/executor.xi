// XIOM - Async: Executor
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.async.executor

// Depends on: xiom.async

// ============================================================================
// Cooperative single-threaded task executor and the block_on entry point.
// NOTE: current implementation lives in async.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Executor - a scheduler owning a ready queue of tasks and pending timers.
// fn executor_new() -> Executor - create an empty executor. TODO(compiler): implement.
// fn executor_spawn(e, f: fn()) - enqueue a task to run on the next drain. TODO(compiler): implement.
// fn executor_spawn_blocking(e, f: fn()) - schedule a blocking task outside the executor thread. TODO(compiler): implement.
// fn executor_run(e) - drive the executor until the queues are empty. TODO(compiler): implement.
// fn executor_run_until_idle(e) - drain currently ready tasks without advancing timers. TODO(compiler): implement.
// fn executor_shutdown(e) - stop accepting tasks and release executor resources. TODO(compiler): implement.
// fn executor_tasks(e) -> Int - the number of queued tasks and timers. TODO(compiler): implement.
// fn block_on(f: fn()) -> Result[Int, Str] - spawn f and drive the global executor to completion. TODO(compiler): implement.
