// p_wave114_shapes.xi -- wave 114 lock: async submodule clause wave
// (channel / executor / timer / io).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the values the wave-114 clauses describe, pre/post:
//   * executor task counts across new/spawn/run/run_until_idle/shutdown;
//   * async channel capacity/closed/length, try_send/try_recv outcomes
//     (incl. the full bounded channel and the closed channel), async_send
//     Ok on open / Err on closed, async_recv Some then None on closed;
//   * broadcast FIFO order, capacity-bounded drop, caught-up None;
//   * timer armed/next state, wheel slot clamp, the parallel-array
//     invariant (ids/deadlines/tasks) across add and cancel, and a
//     no-fire tick;
//   * the ready flag of the io Future wrappers is smoke-covered
//     (smoke_async*.xi); this probe keeps to deterministic pure paths.
// Every returned value is bound before comparing. Returns 0 when all
// cases hold.

module p_wave114_shapes

use xiom.io;
use xiom.async.executor;
use xiom.async.channel;
use xiom.async.timer;

var _hits: Int = 0;

fn bump() {
  _hits = _hits + 1;
}

fn main() -> Int {
  // ---- executor.xi ------------------------------------------------------
  var e = executor.executor_new();
  let n0 = executor.executor_tasks(&e);
  if n0 != 0 { return 1; }
  executor.executor_spawn(&mut e, bump);
  executor.executor_spawn(&mut e, bump);
  let n2 = executor.executor_tasks(&e);
  if n2 != 2 { return 1; }
  executor.executor_run(&mut e);
  let n3 = executor.executor_tasks(&e);
  if n3 != 0 { return 1; }
  let h3 = _hits;
  if h3 != 2 { return 1; }
  executor.executor_spawn_blocking(&mut e, bump);
  executor.executor_run_until_idle(&mut e);
  let n4 = executor.executor_tasks(&e);
  if n4 != 0 { return 1; }
  executor.executor_spawn(&mut e, bump);
  executor.executor_shutdown(&mut e);
  let n5 = executor.executor_tasks(&e);
  if n5 != 0 { return 1; }
  let h5 = _hits;
  if h5 != 3 { return 1; }

  // ---- channel.xi: async channel ---------------------------------------
  var ch = channel.async_channel_new(0); // 0 = unbounded
  let cl0 = channel.async_channel_len(&ch);
  if cl0 != 0 { return 2; }
  let s0 = channel.async_try_send(&mut ch, 41);
  if !s0 { return 2; }
  let cl1 = channel.async_channel_len(&ch);
  if cl1 != 1 { return 2; }
  let r0 = channel.async_try_recv(&mut ch);
  match r0 {
    Some(v) => {
      if v != 41 { return 2; }
    },
    None => { return 2; },
  };
  let s1 = channel.async_send(&mut ch, 7);
  match s1 {
    Ok(_) => {},
    Err(_) => { return 2; },
  };
  channel.async_channel_close(&mut ch);
  let s2 = channel.async_send(&mut ch, 8);
  match s2 {
    Ok(_) => { return 2; },
    Err(_) => {},
  };
  let s3 = channel.async_try_send(&mut ch, 9);
  if s3 { return 2; }
  let r1 = channel.async_recv(&mut ch); // closed but one item queued
  match r1 {
    Some(v) => {
      if v != 7 { return 2; }
    },
    None => { return 2; },
  };
  let r2 = channel.async_recv(&mut ch); // closed and drained
  match r2 {
    Some(_) => { return 2; },
    None => {},
  };

  // bounded channel: full rejects, FIFO drains
  var bch = channel.async_channel_new(2);
  let b1 = channel.async_try_send(&mut bch, 1);
  let b2 = channel.async_try_send(&mut bch, 2);
  let b3 = channel.async_try_send(&mut bch, 3);
  if !b1 { return 2; }
  if !b2 { return 2; }
  if b3 { return 2; }
  let bl = channel.async_channel_len(&bch);
  if bl != 2 { return 2; }
  let bf = channel.async_try_recv(&mut bch);
  match bf {
    Some(v) => {
      if v != 1 { return 2; }
    },
    None => { return 2; },
  };

  // ---- channel.xi: broadcast -------------------------------------------
  var bc = channel.broadcast_new(2);
  channel.broadcast_send(&mut bc, 5);
  channel.broadcast_send(&mut bc, 6);
  channel.broadcast_send(&mut bc, 7); // dropped: at capacity
  let br1 = channel.broadcast_recv(&mut bc);
  match br1 {
    Some(v) => {
      if v != 5 { return 3; }
    },
    None => { return 3; },
  };
  let br2 = channel.broadcast_recv(&mut bc);
  match br2 {
    Some(v) => {
      if v != 6 { return 3; }
    },
    None => { return 3; },
  };
  let br3 = channel.broadcast_recv(&mut bc); // caught up
  match br3 {
    Some(_) => { return 3; },
    None => {},
  };

  // ---- timer.xi ---------------------------------------------------------
  var t = timer.timer_new();
  let tn = timer.timer_next(&t);
  match tn {
    Some(_) => { return 4; },
    None => {},
  };
  var iv = timer.timer_interval(5);
  let ivn = timer.timer_next(&iv);
  match ivn {
    Some(d) => {
      if d < 0 { return 4; }
    },
    None => { return 4; },
  };
  var df = timer.timer_delay(1);
  let dr = df.ready;
  if dr { return 4; }

  var tw = timer.timer_wheel_new(4);
  let ws = tw.slots;
  if ws < 1 { return 4; }
  var tw0 = timer.timer_wheel_new(0); // clamped to >= 1
  let ws0 = tw0.slots;
  if ws0 < 1 { return 4; }

  timer.timer_wheel_add(&mut tw, 1, bump);
  timer.timer_wheel_add(&mut tw, 5, bump);
  let alen = tw.ids.len();
  if alen != 2 { return 4; }
  let dlen = tw.deadlines.len();
  if dlen != 2 { return 4; }
  let tlen = tw.tasks.len();
  if tlen != 2 { return 4; }

  timer.timer_wheel_cancel(&mut tw, 1);
  let clen = tw.ids.len();
  if clen != 1 { return 4; }
  let cdlen = tw.deadlines.len();
  if cdlen != 1 { return 4; }
  let ctlen = tw.tasks.len();
  if ctlen != 1 { return 4; }

  timer.timer_wheel_tick(&mut tw); // now=1; deadline 5 not due
  let after = tw.ids.len();
  if after != 1 { return 4; }
  let anow = tw.now;
  if anow != 1 { return 4; }

  return 0;
}
