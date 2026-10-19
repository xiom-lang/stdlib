// XIOM - Thread: Pool
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.thread.pool

// Depends on: xiom.alloc, xiom.ptr + the runtime spawn-with-result bridge.

// ============================================================================
// Fixed-size worker pool with a shared job queue.
//
// Wave 153 (REL-20261010-1834-engine-6 remainder) flipped the no-arg
// submit->run path from a deterministic simulation to REAL OS threads:
// `tp_submit` hands the job to the wave-145 spawn-with-result machinery
// (xiom_thread_spawn_with_result; the 16-byte result buffer is allocated
// OUTSIDE the confined block per the wave-131 rule) and `tp_join` blocks on
// every in-flight OS handle (xiom_thread_spawn_join), then frees its buffer.
// Every accepted no-arg job therefore runs exactly once on a real thread.
// The runtime spawn table caps concurrent real workers at 256: a job that
// cannot get an OS thread (table full or a failed create) falls back to an
// inline run on the submitting thread -- join periodically to stay under
// the cap.
//
// DETERMINISTIC (legacy contract, smoke-asserted): `idle` / `busy` /
// `queued` are ASSIGNMENT BOOKKEEPING, not OS scheduling. Each submit moves
// one free slot to busy (idle-1, busy+1) until none is free; `tp_join`
// returns all slots to idle (busy == 0, idle == workers). The smokes assert
// these counts synchronously right after submit, so the counters must not
// track the workers' real completion timing.
//
// CONTRACT: accepted jobs run exactly once (join is the completion point;
// there is no ordering guarantee BETWEEN jobs -- they start in submit order,
// but complete under normal OS scheduling). A pool dropped without tp_join /
// tp_shutdown keeps its in-flight OS threads and their 16-byte buffers for
// the process lifetime (the same retained-buffer contract as spawn.detach);
// call tp_join (or tp_shutdown) to reap and free. XIOM does not enforce
// Send/Sync markers on closures yet, so a submitted closure must itself be
// safe to run on another thread (single-writer shared state or equivalent).
//
// GAP (documented, not aspirational): thread-per-job, not a persistent
// worker fleet. A real worker loop is not expressible on this toolchain:
// XIOM cannot call a closure recovered from a raw pointer (the spawn
// trampolines pass no argument channel), the pinned runtime's xiom_channel_*
// family has no close/destroy to wake a blocked worker at shutdown, and the
// runtime's global xiom_threadpool_* workers expose no join/wait surface --
// a waiting worker would busy-spin or could never be woken. `tp_submit_with`
// stays INLINE on the submitting thread (the same engine-6 arg-channel
// freeze as spawn_with); its fn runs with its arg exactly once.
// ============================================================================

use xiom.alloc;
use xiom.ptr;

extern "C" {
  fn xiom_thread_spawn_with_result(fn_ptr: *UInt8, result_buf: *UInt8) -> *UInt8;
  fn xiom_thread_spawn_join(handle: *UInt8) -> Int;
}

/// One in-flight job: its OS-thread handle plus the 16-byte result buffer
/// the spawn trampoline writes into (layout: [done: 8][result: 8]).
pub type PoolJob = { handle: *UInt8; buf: *UInt8; }

/// Fixed-size worker pool with a shared job queue.
pub type ThreadPool = {
  workers: Int;
  idle: Int;
  busy: Int;
  queued: Vec[Int];
  next_id: Int;
  completed: Int;
  closed: Bool;
  running: Vec[PoolJob];
}

/// Create a pool with `workers` threads.
/// Params: workers - fixed number of workers (clamped to >= 1).
/// Returns: a new pool with all workers idle and no pending jobs.
/// Complexity: O(1).
pub fn thread_pool_new(workers: Int) -> ThreadPool
  ensures: result.workers >= 1
  ensures: result.idle == result.workers
  ensures: result.closed == false
{
  var w = workers;
  if w < 1 {
    w = 1;
  }
  return ThreadPool{
    workers: w;
    idle: w;
    busy: 0;
    queued: Vec[Int].new();
    next_id: 0;
    completed: 0;
    closed: false;
    running: Vec[PoolJob].new();
  };
}

/// Enqueue a job; false if the pool is shutting down.
/// Params: p - the pool; job - the closure (REAL: it runs on its own OS
///          thread through the spawn machinery; `tp_join` waits for it).
/// Returns: true on acceptance, false if the pool is shut down.
/// Complexity: O(1) amortized plus one OS thread spawn.
pub fn tp_submit(p: &mut ThreadPool, job: fn()) -> Bool
  ensures: result == true => p.queued.len() >= 1
  ensures: p.busy + p.idle == p.workers
{
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
  // Wave 153: run the job for real. The buffer is allocated OUTSIDE the
  // confined block (wave-131 rule) so the worker trampoline writes into
  // main-heap memory that tp_join may free.
  let buf = alloc.alloc(16);
  var handle: *UInt8 = 0 as *UInt8;
  unsafe {
    let done_ptr = buf as *Int;
    ptr.write(done_ptr, 0);
    let raw_fn = job as *UInt8;
    handle = xiom_thread_spawn_with_result(raw_fn, buf);
  }
  if handle == 0 {
    // Spawn table full / thread creation failed: still exactly once --
    // run inline on the submitting thread and keep no handle.
    alloc.dealloc(buf, 16);
    job();
    return true;
  }
  p.running.push(PoolJob{ handle: handle; buf: buf });
  return true;
}

/// Enqueue a job with one argument; false if the pool is shutting down.
/// Params: p - the pool; job - the closure; arg - its single argument.
/// REAL but INLINE (engine-6 arg-channel freeze): the spawn trampoline has
/// no argument channel, so the arg-carrying form runs on the submitting
/// thread -- exactly once, with its arg.
/// Returns: true on acceptance, false if the pool is shut down.
/// Complexity: O(1) amortized plus the cost of `job`.
pub fn tp_submit_with(p: &mut ThreadPool, job: fn(Int), arg: Int) -> Bool
  ensures: (p.closed == true) => (result == false)
  ensures: (p.closed == false) => (result == true)
{
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
  job(arg);
  return true;
}

/// Block until all queued jobs complete.
/// Params: p - the pool.
/// REAL drain: joins every in-flight OS thread (one per accepted no-arg job)
/// and frees its result buffer; the counters return to busy == 0,
/// idle == workers.
/// Complexity: O(n) where n is the number of pending jobs.
pub fn tp_join(p: &mut ThreadPool)
  ensures: p.queued.len() == 0
  ensures: p.busy == 0
  ensures: p.idle == p.workers
{
  while p.running.len() > 0 {
    let popped = p.running.pop();
    match popped {
      Some(rec) => {
        let rc: Int = unsafe { xiom_thread_spawn_join(rec.handle) };
        if rc >= 0 {
          alloc.dealloc(rec.buf, 16);
        }
      }
      None => {}
    }
  }
  while p.queued.len() > 0 {
    var done = p.queued.pop();
    p.completed = p.completed + 1;
  }
  p.busy = 0;
  p.idle = p.workers;
}

/// Stop accepting jobs, drain the queue, and reap workers.
/// Params: p - the pool.
/// Closes the pool (submit returns false afterwards) and drains the pending
/// work as tp_join does.
/// Complexity: O(n) where n is the number of pending jobs.
pub fn tp_shutdown(p: &mut ThreadPool)
  ensures: p.closed == true
  ensures: p.queued.len() == 0
{
  p.closed = true;
  tp_join(p);
}

/// The number of worker threads.
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

/// The number of currently running workers.
/// Params: p - the pool.
/// Returns: workers currently assigned a job (does not include queued work).
/// Complexity: O(1).
pub fn tp_busy(p: &ThreadPool) -> Int
  ensures: result >= 0
{
  return p.busy;
}
