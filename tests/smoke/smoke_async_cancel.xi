// smoke_async_cancel.xi -- async cancellation semantics (capability gate).
// Covers: executor_shutdown drops every pending task (none run afterwards);
// timer-wheel cancel-all fires nothing, selective cancel fires exactly the
// survivors, unknown cancel ids are no-ops; channel close drains FIFO, then
// recv/try_recv return None and send returns Err / try_send false.
// Deterministic, bounded runtime. Returns 0 on success (prints OK).

module smoke_async_cancel
use xiom.async.executor;
use xiom.async.channel;
use xiom.async.timer;
use xiom.io;

var _fired: Int = 0;

fn bump() {
  _fired = _fired + 1;
}

fn main() -> Int {
  // --- 1) executor shutdown drops all pending tasks ---
  var exec = executor.executor_new();
  var i = 0;
  while i < 1000 {
    executor.executor_spawn(&mut exec, bump);
    i = i + 1;
  };
  if executor.executor_tasks(&exec) != 1000 { io.println("cancel:spawn-count"); return 1; };
  executor.executor_shutdown(&mut exec);
  if executor.executor_tasks(&exec) != 0 { io.println("cancel:shutdown-drain"); return 2; };
  let before = _fired;
  executor.executor_run(&mut exec);
  if _fired != before { io.println("cancel:dropped-ran"); return 3; };
  if executor.executor_tasks(&exec) != 0 { io.println("cancel:tasks-after-run"); return 4; };

  // --- 2) timer wheel: cancel all -> nothing fires ---
  var tw = timer.timer_wheel_new(16);
  i = 1;
  while i <= 100 {
    timer.timer_wheel_add(&mut tw, i, bump);
    i = i + 1;
  };
  i = 1;
  while i <= 100 {
    timer.timer_wheel_cancel(&mut tw, i);
    i = i + 1;
  };
  let b2 = _fired;
  var ticks = 0;
  while ticks < 2000 {
    timer.timer_wheel_tick(&mut tw);
    ticks = ticks + 1;
  };
  if _fired != b2 { io.println("cancel:all-fired"); return 5; };

  // --- 3) selective cancel: exactly the survivors fire; unknown id no-op ---
  // timer ids are monotonic per wheel (not deadlines), so use a fresh wheel:
  // ids 1..3, cancel id 2 -> ids 1 and 3 fire.
  var tw2 = timer.timer_wheel_new(16);
  timer.timer_wheel_add(&mut tw2, 5, bump);
  timer.timer_wheel_add(&mut tw2, 6, bump);
  timer.timer_wheel_add(&mut tw2, 7, bump);
  timer.timer_wheel_cancel(&mut tw2, 2);
  timer.timer_wheel_cancel(&mut tw2, 9999);  // unknown id: must be ignored
  let b3 = _fired;
  ticks = 0;
  while ticks < 500 {
    timer.timer_wheel_tick(&mut tw2);
    ticks = ticks + 1;
  };
  if _fired - b3 != 2 { io.println("cancel:selective"); return 6; };

  // --- 4) channel close: drain FIFO, then None; send fails; try_send false ---
  var ch = channel.async_channel_new(0);
  i = 0;
  while i < 5 {
    let r = channel.async_send(&mut ch, i);
    if r.is_err { io.println("cancel:pre-close-send"); return 7; };
    i = i + 1;
  };
  channel.async_channel_close(&mut ch);
  i = 0;
  while i < 5 {
    let g = channel.async_try_recv(&mut ch);
    match g {
      Some(v) => { if v != i { io.println("cancel:close-fifo"); return 8; }; },
      None => { io.println("cancel:drain-none"); return 9; }
    };
    i = i + 1;
  };
  let g2 = channel.async_try_recv(&mut ch);
  if g2.is_some { io.println("cancel:drained-extra"); return 10; };
  let close_recv = channel.async_recv(&mut ch);
  if close_recv.is_some { io.println("cancel:recv-after-close"); return 11; };
  let s2 = channel.async_send(&mut ch, 42);
  if !s2.is_err { io.println("cancel:send-after-close"); return 12; };
  if channel.async_try_send(&mut ch, 42) { io.println("cancel:try-send-after-close"); return 13; };
  if channel.async_channel_len(&ch) != 0 { io.println("cancel:len"); return 14; };

  io.println("smoke_async_cancel OK");
  return 0;
}
