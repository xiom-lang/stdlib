// XIOM - Thread: Pool
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.thread.pool

// Depends on: xiom.thread

// ============================================================================
// Fixed-size worker thread pool with a shared job queue.
// NOTE: current implementation lives in thread.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type ThreadPool - a pool of worker threads pulling jobs from a queue.
// fn thread_pool_new(workers: Int) -> ThreadPool - create a pool with workers threads. TODO(compiler): implement.
// fn tp_submit(p, job: fn()) -> Bool - enqueue a job; false if the pool is shutting down. TODO(compiler): implement.
// fn tp_submit_with(p, job: fn(Int), arg: Int) -> Bool - enqueue a job with one argument. TODO(compiler): implement.
// fn tp_join(p) - block until all queued jobs complete. TODO(compiler): implement.
// fn tp_shutdown(p) - stop accepting jobs, drain the queue, and reap workers. TODO(compiler): implement.
// fn tp_size(p) -> Int - the number of worker threads. TODO(compiler): implement.
// fn tp_idle(p) -> Int - the number of currently idle workers. TODO(compiler): implement.
// fn tp_busy(p) -> Int - the number of currently running workers. TODO(compiler): implement.
