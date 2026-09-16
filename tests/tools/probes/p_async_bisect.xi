// p_async_bisect.xi -- locate the crashing phase of smoke_async_stress.
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_async_bisect
use xiom.async.executor;
use xiom.async.channel;
use xiom.async.timer;
use xiom.io;

var _n: Int = 0;

fn bump() {
  _n = _n + 1;
}

fn main() -> Int {
  io.println("phase A start");
  io.flush_stdout();
  let tasks = 5000;
  var exec = executor.executor_new();
  var i = 0;
  while i < tasks {
    executor.executor_spawn(&mut exec, bump);
    i = i + 1;
  };
  io.println("A spawned");
  io.flush_stdout();
  if executor.executor_tasks(&exec) != tasks { io.println("A:spawn-count"); return 1; };
  executor.executor_run(&mut exec);
  io.println("A ran");
  io.flush_stdout();
  if _n != tasks { io.println("A:run-count"); return 2; };

  io.println("phase B start");
  io.flush_stdout();
  var ch = channel.async_channel_new(0);
  i = 0;
  while i < 2000 {
    let r = channel.async_send(&mut ch, i);
    if r.is_err { io.println("B:send"); return 3; };
    let g = channel.async_try_recv(&mut ch);
    match g {
      Some(v) => { if v != i { io.println("B:fifo"); return 4; }; },
      None => { io.println("B:none"); return 5; }
    };
    i = i + 1;
  };
  io.println("B done");
  io.flush_stdout();

  io.println("phase C start");
  io.flush_stdout();
  var tw = timer.timer_wheel_new(16);
  i = 0;
  while i < 200 {
    timer.timer_wheel_add(&mut tw, i + 1, bump);
    i = i + 1;
  };
  io.println("C added");
  io.flush_stdout();
  i = 2;
  while i <= 200 {
    timer.timer_wheel_cancel(&mut tw, i);
    i = i + 2;
  };
  io.println("C cancelled");
  io.flush_stdout();
  var before = _n;
  var ticks = 0;
  while ticks < 2000 {
    timer.timer_wheel_tick(&mut tw);
    ticks = ticks + 1;
  };
  io.println("C ticked");
  io.flush_stdout();
  if _n - before != 100 { io.println("C:fire"); return 6; };

  io.println("phase D start");
  io.flush_stdout();
  var bc = channel.broadcast_new(0);
  i = 0;
  while i < 1000 {
    channel.broadcast_send(&mut bc, i);
    i = i + 1;
  };
  io.println("D sent");
  io.flush_stdout();
  i = 0;
  while i < 1000 {
    let g = channel.broadcast_recv(&mut bc);
    match g {
      Some(v) => { if v != i { io.println("D:fifo"); return 7; }; },
      None => { io.println("D:none"); return 8; }
    };
    i = i + 1;
  };
  io.println("P_ASYNC_BISECT OK");
  io.flush_stdout();
  0
}
