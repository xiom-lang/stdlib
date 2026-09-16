// q1_t007_probe.xi -- exercises the whole-body-unsafe fns the Round-19
// catalog flags as lacking `requires` (T007). Compile must be warning-free
// after the Q1 fixes; exit 0 on success.
module q1_t007_probe
use xiom.io;
use xiom.thread;

fn main() -> Int {
  io.print("t");
  io.println("q1");
  var t = io.time_now();
  if t < 0 { return 1; }
  io.sleep(1);
  thread.yield_now();
  thread.sleep(1);
  return 0;
}
