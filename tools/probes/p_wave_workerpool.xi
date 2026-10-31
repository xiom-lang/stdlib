// p_wave_workerpool.xi -- persistent worker fleet + arg channel lock
// (REL-20261010-1834-engine-6 remainder / REL-20261015-2202-pulse item 4).
//
// Rows (0 = all hold):
//  1 -- 100 no-arg jobs over a 4-worker pool run exactly once.
//  2 -- 8 arg jobs (1..8) run exactly once with their args (sum == 36) and
//       at least two distinct worker thread ids are recorded: real
//       concurrency on the persistent fleet, not inline execution.
//  3 -- tp_active returns to 0 and tp_completed counts every job.
//  4 -- tp_shutdown drains 20 queued jobs, wakes the workers, and rejects
//       new submits afterwards.
//  5 -- tp_size/idle/busy bookkeeping is unchanged.
//
// Runs on Windows and Linux; on a platform where the runtime cannot create
// workers the pool degrades to inline execution and row 2/3 fail loudly
// (10+ codes are setup failures).
module p_wave_workerpool

use xiom.alloc;
use xiom.ptr;
use xiom.thread;
use xiom.thread.pool;

extern "C" {
  fn xiom_atomic_load(ptr: *Int) -> Int;
  fn xiom_atomic_fetch_add(ptr: *Int, val: Int) -> Int;
}

var _ids_base: Int = 0;
var _idx_p: *Int = 0 as *Int;
var _sum_p: *Int = 0 as *Int;
var _plain_p: *Int = 0 as *Int;
var _main_tid: Int = 0;

fn plain_job()
  requires: true
{
  unsafe { let _ = xiom_atomic_fetch_add(_plain_p, 1); }
}

fn record_job(arg: Int)
  requires: true
{
  let i: Int = unsafe { xiom_atomic_fetch_add(_idx_p, 1) };
  let slot: *Int = unsafe { (_ids_base + i * 8) as *Int };
  unsafe { ptr.write(slot, thread.current_thread_id()); }
  unsafe { let _ = xiom_atomic_fetch_add(_sum_p, arg); }
  thread.sleep_ms(10);
}

fn main() -> Int {
  var p = pool.thread_pool_new(4);
  if pool.tp_size(&p) != 4 { return 10; }
  if pool.tp_idle(&p) != 4 { return 11; }
  if pool.tp_busy(&p) != 0 { return 12; }

  // Shared cells: 64 thread-id slots + 3 counters.
  let ids = alloc.alloc(64 * 8);
  let idx = alloc.alloc(8);
  let sum = alloc.alloc(8);
  let plain = alloc.alloc(8);
  unsafe {
    _ids_base = ids as Int;
    _idx_p = idx as *Int;
    _sum_p = sum as *Int;
    _plain_p = plain as *Int;
  }
  _main_tid = thread.current_thread_id();
  unsafe {
    ptr.write(_idx_p, 0);
    ptr.write(_sum_p, 0);
    ptr.write(_plain_p, 0);
  }

  // Row 1: no-arg jobs, exactly once.
  var i = 0;
  while i < 100 {
    if !pool.tp_submit(&mut p, plain_job) { return 13; }
    i = i + 1;
  }
  pool.tp_join(&mut p);
  if unsafe { xiom_atomic_load(_plain_p) } != 100 { return 1; }

  // Row 2: arg jobs + real concurrency.
  i = 0;
  while i < 8 {
    let arg = i + 1;
    if !pool.tp_submit_with(&mut p, record_job, arg) { return 14; }
    i = i + 1;
  }
  pool.tp_join(&mut p);
  if unsafe { xiom_atomic_load(_sum_p) } != 36 { return 2; }
  var distinct = 0;
  var main_seen = 0;
  var a = 0;
  while a < 8 {
    let slot: *Int = unsafe { (_ids_base + a * 8) as *Int };
    let tid = unsafe { ptr.read(slot) };
    if tid == _main_tid { main_seen = main_seen + 1; }
    var b = 0;
    var dup = 0;
    while b < a {
      let other: *Int = unsafe { (_ids_base + b * 8) as *Int };
      if unsafe { ptr.read(other) } == tid { dup = 1; }
      b = b + 1;
    }
    if dup == 0 { distinct = distinct + 1; }
    a = a + 1;
  }
  if main_seen != 0 { return 3; }
  if distinct < 2 { return 4; }

  // Row 3: completion accounting.
  if pool.tp_active(&p) != 0 { return 5; }
  if pool.tp_completed(&p) < 108 { return 6; }
  if pool.tp_busy(&p) != 0 { return 7; }
  if pool.tp_idle(&p) != 4 { return 8; }

  // Row 4: shutdown drains queued work and rejects new submits.
  i = 0;
  while i < 20 {
    if !pool.tp_submit_with(&mut p, record_job, 1) { return 15; }
    i = i + 1;
  }
  pool.tp_shutdown(&mut p);
  if pool.tp_submit(&mut p, plain_job) { return 9; }
  if pool.tp_submit_with(&mut p, record_job, 1) { return 16; }
  if pool.tp_active(&p) != 0 { return 17; }

  pool.tp_destroy(&mut p);
  return 0;
}
