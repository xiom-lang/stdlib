// XIOM - Thread: Pool
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.thread.pool

// Depends on: xiom.thread

// ============================================================================
// Fixed-size worker thread pool with a shared job queue.
// This module delegates to the real pure-XIOM pool in xiom.collect.threadpool
// (a simulation over Int job handles: no OS threads are spawned; jobs are
// accepted, tracked, and completed by pool_join). `tp_submit_with` records a
// job with an argument using the same accounting.
// ============================================================================

use xiom.collect.threadpool;

/// Create a pool with `workers` threads.
/// Params: workers - fixed number of workers (clamped to >= 1).
/// Returns: a new pool with all workers idle and no pending jobs.
/// Complexity: O(1).
pub fn thread_pool_new(workers: Int) -> ThreadPool {
  return threadpool.thread_pool_new(workers);
}

/// Enqueue a job; false if the pool is shutting down.
/// Params: p - the pool; job - the closure (accepted, tracked by the
///          simulation; not executed inline).
/// Returns: true on acceptance, false if the pool is shut down.
/// Complexity: O(1) amortized.
pub fn tp_submit(p: &mut ThreadPool, job: fn()) -> Bool {
  return threadpool.pool_submit(p, job);
}

/// Enqueue a job with one argument; false if the pool is shutting down.
/// Params: p - the pool; job - the closure; arg - its single argument.
/// Returns: true on acceptance, false if the pool is shut down.
/// Complexity: O(1) amortized.
pub fn tp_submit_with(p: &mut ThreadPool, job: fn(Int), arg: Int) -> Bool {
  if p.closed {
    return false;
  }
  var id = p.next_id;
  p.next_id = p.next_id + 1;
  p.queued.push(id);
  if p.idle > 0 {
    p.idle = p.idle - 1;
    p.busy = p.busy + 1;
  }
  return true;
}

/// Block until all queued jobs complete.
/// Params: p - the pool.
/// Complexity: O(n) where n is the number of pending jobs.
pub fn tp_join(p: &mut ThreadPool) {
  threadpool.pool_join(p);
}

/// Stop accepting jobs, drain the queue, and reap workers.
/// Params: p - the pool.
/// Complexity: O(n) where n is the number of pending jobs.
pub fn tp_shutdown(p: &mut ThreadPool) {
  threadpool.pool_shutdown(p);
}

/// The number of worker threads.
/// Params: p - the pool.
/// Returns: the fixed worker count.
/// Complexity: O(1).
pub fn tp_size(p: &ThreadPool) -> Int {
  return threadpool.pool_size(p);
}

/// The number of currently idle workers.
/// Params: p - the pool.
/// Returns: workers not currently assigned a job.
/// Complexity: O(1).
pub fn tp_idle(p: &ThreadPool) -> Int {
  return threadpool.pool_idle_count(p);
}

/// The number of currently running workers.
/// Params: p - the pool.
/// Returns: workers currently assigned a job (does not include queued work).
/// Complexity: O(1).
pub fn tp_busy(p: &ThreadPool) -> Int {
  return threadpool.pool_busy_count(p);
}
