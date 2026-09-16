// smoke_async_stress.xi -- xiom.async stress suite (capability gate).
// Scales the smoke_async surface: executor task storm (2000 spawns with
// side-effect verification), channel FIFO saturation, timer-wheel
// fire/cancel storm, broadcast ordering. Deterministic, bounded runtime.
// Returns 0 on success (prints OK); nonzero + tag on failure.
//
// NOTE: the executor's stored-fn invocation was shape-dependent on this
// toolchain (see COMPILER_BUGS R23, FIXED in 2e06a3e7). This smoke keeps
// the full async surface of smoke_async and scales the counts; reduced
// shapes are covered by smoke_async_cancel.xi and the p_async_p5/p7/p9
// probes.

module smoke_async_stress
use xiom.async.executor;
use xiom.async.timer;
use xiom.async.io.async_write_file;
use xiom.async.io.async_read_file;
use xiom.async.channel;
use xiom.io;
use xiom.convert;

var _n: Int = 0;

fn bump() {
  _n = _n + 1;
}

fn wheel_bump() {
  _n = _n + 10;
}

fn main() -> Int {
  // --- 1) executor task storm: 2000 spawns, all must run, queue drains ---
  var exec = executor.executor_new();
  if executor.executor_tasks(&exec) != 0 { io.println("xs:new"); return 1; }
  var i = 0;
  while i < 2000 {
    executor.executor_spawn(&mut exec, bump);
    i = i + 1;
  };
  if executor.executor_tasks(&exec) != 2000 { io.println("xs:spawn-count"); return 2; }
  executor.executor_run(&mut exec);
  if _n != 2000 { io.println("xs:run-count"); return 3; }
  if executor.executor_tasks(&exec) != 0 { io.println("xs:drained"); return 4; }

  // --- 2) channel FIFO saturation: 2000 send + try_recv pairs ---
  var ach = channel.async_channel_new(0);
  i = 0;
  while i < 2000 {
    let r = channel.async_send(&mut ach, i);
    if r.is_err { io.println("xs:send"); return 5; }
    let g = channel.async_try_recv(&mut ach);
    match g {
      Some(v) => { if v != i { io.println("xs:fifo"); return 6; } }
      None => { io.println("xs:recv-none"); return 7; }
    };
    i = i + 1;
  };
  if channel.async_channel_len(&ach) != 0 { io.println("xs:chan-empty"); return 8; }

  // --- 3) broadcast ordering: 1000 items ---
  var bd = channel.broadcast_new(0);
  i = 0;
  while i < 1000 {
    channel.broadcast_send(&mut bd, i);
    i = i + 1;
  };
  i = 0;
  while i < 1000 {
    let br = channel.broadcast_recv(&mut bd);
    match br {
      Some(v) => { if v != i { io.println("xs:bc-fifo"); return 9; } }
      None => { io.println("xs:bc-none"); return 10; }
    };
    i = i + 1;
  };

  // --- 4) executor misc surface (kept for shape; also smoke_async's locks) ---
  var exec2 = executor.executor_new();
  executor.executor_spawn_blocking(&mut exec2, bump);
  executor.executor_run_until_idle(&mut exec2);
  if executor.executor_tasks(&exec2) != 0 { io.println("xs:idle"); return 11; }
  var br2 = executor.block_on(bump);
  if br2.is_err { io.println("xs:block_on"); return 12; }
  var exec3 = executor.executor_new();
  executor.executor_spawn(&mut exec3, bump);
  executor.executor_shutdown(&mut exec3);
  if executor.executor_tasks(&exec3) != 0 { io.println("xs:shutdown"); return 13; }

  // --- 5) timers: delay + inert checks + sleep ---
  var t = timer.timer_new();
  var tn = timer.timer_next(t);
  match tn {
    Some(_) => { io.println("xs:timer-inert"); return 14; }
    None => {}
  }
  var f = timer.timer_delay(10);
  if f.ready { io.println("xs:delay-ready"); return 15; }
  timer.timer_sleep(5);

  // --- 6) timer wheel storm: 200 added, evens cancelled, exactly 100 fire ---
  var tw = timer.timer_wheel_new(16);
  i = 0;
  while i < 200 {
    timer.timer_wheel_add(&mut tw, i + 1, wheel_bump);
    i = i + 1;
  };
  i = 2;
  while i <= 200 {
    timer.timer_wheel_cancel(&mut tw, i);
    i = i + 2;
  };
  var before = _n;
  var ticks = 0;
  while ticks < 2000 {
    timer.timer_wheel_tick(&mut tw);
    ticks = ticks + 1;
  };
  if _n - before != 1000 { io.println("xs:wheel-fire"); return 16; }
  i = 0;
  while i < 100 {
    timer.timer_wheel_tick(&mut tw);
    i = i + 1;
  };
  if _n - before != 1000 { io.println("xs:wheel-refire"); return 17; }

  // --- 7) stopwatch ---
  var sw = timer.stopwatch_new();
  var e1 = timer.stopwatch_split(sw);
  timer.timer_sleep(5);
  var e2 = timer.stopwatch_elapsed_ms(sw);
  if e2 < e1 { io.println("xs:stopwatch"); return 18; }
  timer.stopwatch_reset(&mut sw);
  if timer.stopwatch_elapsed_ms(sw) < 0 { io.println("xs:sw-reset"); return 19; }

  // --- 8) async io (kept for shape + regression lock) ---
  var data = bytes("async-stress-io");
  var wf = async_write_file("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_async_stress_io.txt", &data);
  if !wf.ready { io.println("xs:io-write-ready"); return 20; }
  if wf.value != 15 { io.println("xs:io-write-val"); return 21; }
  var rf = async_read_file("C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\smoke_async_stress_io.txt");
  if !rf.ready { io.println("xs:io-read-ready"); return 22; }
  if rf.data.len() != 15 { io.println("xs:io-read-len"); return 23; }

  io.println("OK");
  return 0;
}

fn bytes(s: Str) -> Vec[UInt8] {
  var out: Vec[UInt8] = Vec[UInt8]::with_capacity(s.len() as UInt);
  var i: Int = 0;
  while i < s.len() {
    out.push(s.byte_at(i));
    i = i + 1;
  };
  return out;
}
