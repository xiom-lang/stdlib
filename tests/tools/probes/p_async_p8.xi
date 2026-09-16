// p_async_p8.xi -- P6 + the xiom.async.io imports that smoke_async has.
module p_async_p8
use xiom.async.executor;
use xiom.async.io.async_write_file;
use xiom.async.io.async_read_file;
use xiom.convert;
use xiom.io;

var _n: Int = 0;

fn bump() {
  _n = _n + 1;
}

fn main() -> Int {
  var exec = executor.executor_new();
  executor.executor_spawn(&mut exec, bump);
  if executor.executor_tasks(&exec) != 1 { return 1; };
  executor.executor_run(&mut exec);
  if executor.executor_tasks(&exec) != 0 { return 2; };
  if _n != 1 { io.println("P8 n=" + convert.int_to_string(_n)); return 3; };
  io.println("P8 OK");
  0
}
