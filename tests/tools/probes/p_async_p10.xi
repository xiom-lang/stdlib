// p_async_p10.xi -- P7 shape plus channel/timer calls (closure shape test).
module p_async_p10
use xiom.async.executor;
use xiom.async.channel;
use xiom.async.timer;
use xiom.convert;
use xiom.io;

var _n: Int = 0;

fn bump() {
  _n = _n + 1;
}

fn main() -> Int {
  var ch = channel.async_channel_new(0);
  var ts = timer.timer_new();
  var exec = executor.executor_new();
  executor.executor_spawn(&mut exec, bump);
  executor.executor_spawn(&mut exec, bump);
  if executor.executor_tasks(&exec) != 2 { return 1; };
  executor.executor_run(&mut exec);
  if executor.executor_tasks(&exec) != 0 { return 2; };
  if _n != 2 { io.println("P10 n=" + convert.int_to_string(_n)); return 3; };
  io.println("P10 OK");
  0
}
