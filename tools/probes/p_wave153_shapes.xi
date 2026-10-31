// p_wave153_shapes.xi -- wave 153 lock: the pool flip
// (REL-20261010-1834-engine-6 remainder). xiom.thread.pool's no-arg
// submit->run path is REAL OS-thread execution over the wave-145
// spawn-with-result machinery; the idle/busy/queued counts stay
// deterministic assignment bookkeeping.
// Rows (0 = all hold):
//  1 -- 12 distinct tasks over a 4-worker pool all complete exactly once:
//       every per-task module-global slot reads exactly 1 after tp_join and
//       the total is 12 (one writer per slot -> race-free; a double run
//       would read 2, a swallowed task 0).
//  2 -- assignment counts are deterministic synchronously: busy/idle track
//       each submit up to the 4-worker cap; after tp_join busy == 0 and
//       idle == 4.
//  3 -- a pooled task ran on a non-main OS thread (real execution witness).
//  4 -- tp_submit_with runs its fn with its arg on a worker (real arg
//       channel; join is the completion point).
//  5 -- tp_shutdown rejects new submits (both forms).
//  6 -- tp_size == 4, initial idle == 4, initial busy == 0.
// Setup failures use 10+ (never a silent pass).
//
// Landmine: no xiom.thread.spawn import (module-name collision, BUG 25 #9);
// current_thread_id comes from xiom.thread.

module p_wave153_shapes

use xiom.thread.pool;
use xiom.thread;

var _s1: Int = 0;
var _s2: Int = 0;
var _s3: Int = 0;
var _s4: Int = 0;
var _s5: Int = 0;
var _s6: Int = 0;
var _s7: Int = 0;
var _s8: Int = 0;
var _s9: Int = 0;
var _s10: Int = 0;
var _s11: Int = 0;
var _s12: Int = 0;
var _worker_tid: Int = 0;
var _arg_seen: Int = -1;
var _arg_tid: Int = 0;

fn task1() {
  _s1 = _s1 + 1;
  _worker_tid = thread.current_thread_id();
}

fn task2() { _s2 = _s2 + 1; }
fn task3() { _s3 = _s3 + 1; }
fn task4() { _s4 = _s4 + 1; }
fn task5() { _s5 = _s5 + 1; }
fn task6() { _s6 = _s6 + 1; }
fn task7() { _s7 = _s7 + 1; }
fn task8() { _s8 = _s8 + 1; }
fn task9() { _s9 = _s9 + 1; }
fn task10() { _s10 = _s10 + 1; }
fn task11() { _s11 = _s11 + 1; }
fn task12() { _s12 = _s12 + 1; }

fn add_arg(x: Int) {
  _arg_seen = x;
  _arg_tid = thread.current_thread_id();
}

fn main() -> Int {
  var p = pool.thread_pool_new(4);
  if pool.tp_size(&p) != 4 { return 10; }
  if pool.tp_idle(&p) != 4 { return 11; }
  if pool.tp_busy(&p) != 0 { return 12; }

  // Submit 12 distinct capture-less tasks; watch the deterministic
  // assignment counts while the real threads run.
  if !pool.tp_submit(&mut p, task1) { return 13; }
  if pool.tp_busy(&p) != 1 { return 14; }
  if pool.tp_idle(&p) != 3 { return 15; }
  if !pool.tp_submit(&mut p, task2) { return 16; }
  if pool.tp_busy(&p) != 2 { return 17; }
  if !pool.tp_submit(&mut p, task3) { return 18; }
  if !pool.tp_submit(&mut p, task4) { return 19; }
  if pool.tp_busy(&p) != 4 { return 20; }
  if pool.tp_idle(&p) != 0 { return 21; }
  if !pool.tp_submit(&mut p, task5) { return 22; }
  if !pool.tp_submit(&mut p, task6) { return 23; }
  if !pool.tp_submit(&mut p, task7) { return 24; }
  if !pool.tp_submit(&mut p, task8) { return 25; }
  if !pool.tp_submit(&mut p, task9) { return 26; }
  if !pool.tp_submit(&mut p, task10) { return 27; }
  if !pool.tp_submit(&mut p, task11) { return 28; }
  if !pool.tp_submit(&mut p, task12) { return 29; }
  if pool.tp_busy(&p) != 4 { return 30; }
  if pool.tp_idle(&p) != 0 { return 31; }

  pool.tp_join(&mut p);

  // Row 2: deterministic counts after join.
  if pool.tp_busy(&p) != 0 { return 2; }
  if pool.tp_idle(&p) != 4 { return 3; }

  // Row 1: exactly-once per task + total.
  if _s1 != 1 || _s2 != 1 || _s3 != 1 || _s4 != 1 { return 1; }
  if _s5 != 1 || _s6 != 1 || _s7 != 1 || _s8 != 1 { return 1; }
  if _s9 != 1 || _s10 != 1 || _s11 != 1 || _s12 != 1 { return 1; }
  let total = _s1 + _s2 + _s3 + _s4 + _s5 + _s6 + _s7 + _s8 + _s9 + _s10 + _s11 + _s12;
  if total != 12 { return 1; }

  // Row 3: real OS thread.
  if _worker_tid == 0 { return 32; }
  if _worker_tid == thread.current_thread_id() { return 4; }

  // Row 4: tp_submit_with runs its fn with its arg.
  if !pool.tp_submit_with(&mut p, add_arg, 77) { return 33; }
  pool.tp_join(&mut p);
  if _arg_seen != 77 { return 5; }
  if _arg_tid == 0 { return 34; }
  if _arg_tid == thread.current_thread_id() { return 35; }

  // Row 5: shutdown rejects new submits.
  pool.tp_shutdown(&mut p);
  if pool.tp_submit(&mut p, task1) { return 6; }
  if pool.tp_submit_with(&mut p, add_arg, 5) { return 7; }

  return 0;
}
