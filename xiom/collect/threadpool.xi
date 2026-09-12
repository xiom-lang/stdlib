// XIOM - Collections: Thread Pool
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.threadpool

// Depends on: xiom.thread, xiom.sync

// ============================================================================
// Thread pool. Spawns a fixed number of worker threads that drain a shared job
// queue. pool_submit enqueues a closure; pool_join waits for all pending jobs
// to finish; pool_shutdown stops the workers and releases their threads.
//
// Pure-XIOM data structure (no OS threads): the pool tracks `workers` worker
// slots, an `idle`/`busy` split and a FIFO queue of Int job handles. Each
// submit hands the job to an idle worker if one is free (busy++), otherwise
// the handle waits in the queue; pool_join completes every pending job
// instantly (no real work runs) and returns all workers to idle. Submit after
// shutdown returns false.
// ============================================================================

pub type ThreadPool = {
  workers: Int;
  idle: Int;
  busy: Int;
  queued: Vec[Int];
  next_id: Int;
  completed: Int;
  closed: Bool;
}

/// Create a pool with `workers` worker slots.
/// Params: workers - fixed number of workers (clamped to >= 1).
/// Returns: a new pool with all workers idle and no pending jobs.
/// Complexity: O(1).
pub fn thread_pool_new(workers: Int) -> ThreadPool {
  var w = workers;
  if w < 1 { w = 1; }
  return ThreadPool{ workers: w; idle: w; busy: 0; queued: Vec[Int].new(); next_id: 0; completed: 0; closed: false; };
}

/// Enqueue a job; false if the pool is shut down.
/// Params: p - the pool; job - a closure (accepted but not executed; the
/// pool is a pure-XIOM simulation over Int job handles).
/// Returns: true on acceptance, false if the pool is shut down.
/// Complexity: O(1) amortized.
pub fn pool_submit(p: &mut ThreadPool, job: fn()) -> Bool {
  if p.closed { return false; }
  var id = p.next_id;
  p.next_id = p.next_id + 1;
  p.queued.push(id);
  if p.idle > 0 {
    p.idle = p.idle - 1;
    p.busy = p.busy + 1;
  }
  return true;
}

/// Wait until all submitted jobs have completed.
/// Params: p - the pool.
/// Completes every queued job (they finish immediately in the simulation) and
/// returns all workers to the idle state.
/// Complexity: O(n) where n is the number of pending jobs.
pub fn pool_join(p: &mut ThreadPool) {
  while p.queued.len() > 0 {
    var done = p.queued.pop();
    p.completed = p.completed + 1;
  }
  p.busy = 0;
  p.idle = p.workers;
}

/// Stop workers and release threads.
/// Params: p - the pool.
/// Closes the pool (submit returns false afterwards) and drains the pending
/// queue as pool_join does.
/// Complexity: O(n) where n is the number of pending jobs.
pub fn pool_shutdown(p: &mut ThreadPool) {
  p.closed = true;
  pool_join(p);
}

/// Number of worker threads.
/// Params: p - the pool.
/// Returns: the fixed worker count.
/// Complexity: O(1).
pub fn pool_size(p: &ThreadPool) -> Int
  ensures: result >= 0
{
  return p.workers;
}

/// Number of workers currently idle.
/// Params: p - the pool.
/// Returns: workers not currently assigned a job.
/// Complexity: O(1).
pub fn pool_idle_count(p: &ThreadPool) -> Int
  ensures: result >= 0
{
  return p.idle;
}

/// Number of workers currently running a job.
/// Params: p - the pool.
/// Returns: workers currently assigned a job (does not include queued work).
/// Complexity: O(1).
pub fn pool_busy_count(p: &ThreadPool) -> Int
  ensures: result >= 0
{
  return p.busy;
}
