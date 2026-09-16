// p_async_p1.xi -- async imports only; does the process start?
module p_async_p1
use xiom.async.executor;
use xiom.async.channel;
use xiom.async.timer;
use xiom.io;

fn main() -> Int {
  io.println("P1 OK");
  io.flush_stdout();
  0
}
