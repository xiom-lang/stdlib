// XIOM - Thread: Pool
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.thread.pool

// Depends on: xiom.alloc, xiom.ptr + the runtime worker-pool ABI.

// ============================================================================
// Fixed-size persistent worker pool.
//
// Since REL-20261010-1834-engine-6 the pool is a REAL persistent fleet, not
// thread-per-job: `thread_pool_new` creates N OS workers in the runtime
// (`xiom_workerpool_create`) that block on one condition variable and drain a
// bounded FIFO queue. Submit never spawns a thread; `tp_join` waits until
// queued + running reaches zero (a true completion point), and `tp_shutdown`
// wakes every worker and joins the OS threads.
//
// `tp_submit_with(p, f, arg)` runs `f(arg)` on a worker too. The runtime
// calls the bare code pointer through the same function-pointer ABI the
// wave-145 spawn trampoline uses; the i64 argument travels in the payload.
// Send/Sync markers are still documentation-only (compiler scope): a job
// must itself be safe to run on another thread.
//
// JOB FORM: pass a named/top-level function (or an explicit raw code
// pointer). A capturing closure is represented as an environment, not a
// bare code pointer, so `job as *UInt8` would hand the worker the env and
// crash -- the same contract as `spawn`. Non-capturing named jobs only.
//
// DETERMINISTIC (legacy contract, smoke-asserted): `idle` / `busy` /
// `queued` are ASSIGNMENT BOOKKEEPING, not OS scheduling. Each submit moves
// one free slot to busy (idle-1, busy+1) until none is free; `tp_join`
// returns all slots to idle (busy == 0, idle == workers). The smokes assert
// these counts synchronously right after submit, so the counters must not
// track the workers' real completion timing. `tp_active` / `tp_completed`
// expose the runtime's real outstanding/completed counters.
//
// CONTRACT: accepted jobs run exactly once; `tp_join` is the completion
// point. Submit blocks while the queue is full. A pool destroyed without
// `tp_destroy` keeps its worker threads (and their stack) until the process
// exits; call `tp_shutdown`/`tp_destroy` to release them. A job that never
// returns makes shutdown block (same contract as a non-terminating thread).
// If the runtime cannot create the workers, the pool degrades to inline
// execution (documented; submit still runs each accepted job exactly once).
// ============================================================================

use xiom.alloc;
use xiom.ptr;

extern "C" {
  fn xiom_workerpool_create(workers: Int) -> *UInt8;
  fn xiom_workerpool_submit(pool: *UInt8, fn_ptr: *UInt8) -> Int32;
  fn xiom_workerpool_submit_with(pool: *UInt8, fn_ptr: *UInt8, arg: Int) -> Int32;
  fn xiom_workerpool_join(pool: *UInt8) -> Int;
  fn xiom_workerpool_shutdown(pool: *UInt8);
  fn xiom_workerpool_destroy(pool: *UInt8);
  fn xiom_workerpool_size(pool: *UInt8) -> Int32;
  fn xiom_workerpool_active(pool: *UInt8) -> Int;
  fn xiom_workerpool_completed(pool: *UInt8) -> Int;
}

/// Legacy per-job record (kept for source compatibility; the persistent
/// fleet no longer stores per-job handles).
pub type PoolJob = { handle: *UInt8; buf: *UInt8; }

/// Fixed-size persistent worker pool.
pub type ThreadPool = {
  workers: Int;
  idle: Int;
  busy: Int;
  queued: Vec[Int];
  next_id: Int;
  completed: Int;
  closed: Bool;
  /// Legacy, always empty (thread-per-job handles are gone).
  running: Vec[PoolJob];
  /// Runtime pool handle (0 = degraded inline mode).
  handle: *UInt8;
}

/// Create a pool with `workers` persistent workers.
/// Params: workers - fixed number of workers (clamped to >= 1).
/// Returns: a new pool with all workers idle and no pending jobs.
/// Complexity: O(workers) OS thread creation.
pub fn thread_pool_new(workers: Int) -> ThreadPool
  ensures: result.workers >= 1
  ensures: result.idle == result.workers
  ensures: result.closed == false
{
  var w = workers;
  if w < 1 {
    w = 1;
  }
  var h: *UInt8 = 0 as *UInt8;
  unsafe { h = xiom_workerpool_create(w); }
  return ThreadPool{
    workers: w;
    idle: w;
    busy: 0;
    queued: Vec[Int].new();
    next_id: 0;
    completed: 0;
    closed: false;
    running: Vec[PoolJob].new();
    handle: h;
  };
}

fn _assign(p: &mut ThreadPool) {
  if p.idle > 0 {
    p.idle = p.idle - 1;
    p.busy = p.busy + 1;
  }
}

fn _release(p: &mut ThreadPool) {
  p.busy = 0;
  p.idle = p.workers;
}

fn _drain_queue(p: &mut ThreadPool) {
  while p.queued.len() > 0 {
    let _ = p.queued.pop();
    p.completed = p.completed + 1;
  }
}

/// Enqueue a job; false if the pool is shutting down.
/// Params: p - the pool; job - a named/top-level closure (runs on a
///         persistent worker; capturing closures are not representable as
///         bare code pointers -- see the module contract).
/// Returns: true on acceptance, false if the pool is shut down.
/// Complexity: O(1) amortized (blocks while the queue is full).
pub fn tp_submit(p: &mut ThreadPool, job: fn()) -> Bool
  ensures: result == true => p.queued.len() >= 1
  ensures: p.busy + p.idle == p.workers
{
  if p.closed {
    return false;
  }
  if p.handle != 0 {
    var ok: Int32 = 0;
    unsafe { ok = xiom_workerpool_submit(p.handle, job as *UInt8); }
    if ok == 0 {
      p.closed = true;
      return false;
    }
  } else {
    // Degraded mode: no runtime workers.
    job();
  }
  _assign(p);
  p.queued.push(p.next_id);
  p.next_id = p.next_id + 1;
  return true;
}

/// Enqueue a job with one argument; false if the pool is shutting down.
/// Params: p - the pool; job - the closure; arg - its single argument.
/// Runs on a persistent worker with `arg` (no longer inline).
/// Returns: true on acceptance, false if the pool is shut down.
/// Complexity: O(1) amortized (blocks while the queue is full).
pub fn tp_submit_with(p: &mut ThreadPool, job: fn(Int), arg: Int) -> Bool
  ensures: (p.closed == true) => (result == false)
  ensures: (p.closed == false) => (result == true)
{
  if p.closed {
    return false;
  }
  if p.handle != 0 {
    var ok: Int32 = 0;
    unsafe { ok = xiom_workerpool_submit_with(p.handle, job as *UInt8, arg); }
    if ok == 0 {
      p.closed = true;
      return false;
    }
  } else {
    job(arg);
  }
  _assign(p);
  p.queued.push(p.next_id);
  p.next_id = p.next_id + 1;
  return true;
}

/// Block until all queued and running jobs complete.
/// Params: p - the pool.
/// REAL drain: waits for the runtime's outstanding counter to reach zero,
/// then returns the assignment counters to busy == 0, idle == workers.
/// Complexity: O(1) wait plus the workers' runtime.
pub fn tp_join(p: &mut ThreadPool)
  ensures: p.queued.len() == 0
  ensures: p.busy == 0
  ensures: p.idle == p.workers
{
  if p.handle != 0 {
    unsafe { let _ = xiom_workerpool_join(p.handle); }
  }
  _drain_queue(p);
  _release(p);
}

/// Stop accepting jobs, drain the queue, and reap the workers.
/// Params: p - the pool.
/// Closes the pool (submit returns false afterwards), waits for completion,
/// wakes every worker and joins the OS threads.
/// Complexity: O(n) where n is the pending work.
pub fn tp_shutdown(p: &mut ThreadPool)
  ensures: p.closed == true
  ensures: p.queued.len() == 0
{
  p.closed = true;
  if p.handle != 0 {
    unsafe {
      let _ = xiom_workerpool_join(p.handle);
      xiom_workerpool_shutdown(p.handle);
    }
  }
  _drain_queue(p);
  _release(p);
}

/// Shut the pool down and free its runtime resources.
/// Params: p - the pool (consumed).
/// Do not call while another thread may still submit.
/// Complexity: O(n) where n is the pending work.
pub fn tp_destroy(p: &mut ThreadPool)
  ensures: p.closed == true
  ensures: p.busy == 0
  ensures: p.idle == p.workers
{
  p.closed = true;
  if p.handle != 0 {
    unsafe { xiom_workerpool_destroy(p.handle); }
    p.handle = 0 as *UInt8;
  }
  _drain_queue(p);
  _release(p);
}

/// The number of persistent workers.
/// Params: p - the pool.
/// Returns: the fixed worker count.
/// Complexity: O(1).
pub fn tp_size(p: &ThreadPool) -> Int
  ensures: result >= 0
{
  return p.workers;
}

/// The number of currently idle workers.
/// Params: p - the pool.
/// Returns: workers not currently assigned a job.
/// Complexity: O(1).
pub fn tp_idle(p: &ThreadPool) -> Int
  ensures: result >= 0
{
  return p.idle;
}

/// The number of currently assigned workers.
/// Params: p - the pool.
/// Returns: workers currently assigned a job (does not include queued work).
/// Complexity: O(1).
pub fn tp_busy(p: &ThreadPool) -> Int
  ensures: result >= 0
{
  return p.busy;
}

/// The real number of queued + running jobs.
/// Params: p - the pool.
/// Returns: the runtime outstanding count (0 in degraded mode).
/// Complexity: O(1) plus one lock.
pub fn tp_active(p: &ThreadPool) -> Int
  ensures: result >= 0
{
  if p.handle == 0 {
    return 0;
  }
  unsafe { return xiom_workerpool_active(p.handle); }
}

/// The real number of jobs completed by the workers.
/// Params: p - the pool.
/// Returns: the runtime completed counter (0 in degraded mode).
/// Complexity: O(1) plus one lock.
pub fn tp_completed(p: &ThreadPool) -> Int
  ensures: result >= 0
{
  if p.handle == 0 {
    return 0;
  }
  unsafe { return xiom_workerpool_completed(p.handle); }
}
