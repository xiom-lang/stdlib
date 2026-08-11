// XIOM - Collections: Thread Pool
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.threadpool

// Depends on: xiom.thread, xiom.sync

// ============================================================================
// Thread pool. Spawns a fixed number of worker threads that drain a shared job
// queue. pool_submit enqueues a closure; pool_join waits for all pending jobs
// to finish; pool_shutdown stops the workers and releases their threads.
// ============================================================================

// fn thread_pool_new(workers: Int) - create a pool with workers threads. TODO(compiler): implement.
// fn pool_submit(p, job: fn()) -> Bool - enqueue a job; false if the pool is shut down. TODO(compiler): implement.
// fn pool_join(p) - wait until all submitted jobs have completed. TODO(compiler): implement.
// fn pool_shutdown(p) - stop workers and release threads. TODO(compiler): implement.
// fn pool_size(p) -> Int - number of worker threads. TODO(compiler): implement.
// fn pool_idle_count(p) -> Int - number of workers currently idle. TODO(compiler): implement.
// fn pool_busy_count(p) -> Int - number of workers currently running a job. TODO(compiler): implement.
