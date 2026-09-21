// p_async_p4.xi -- executor spawn + run with a stored callback.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_async_p4
use xiom.async.executor;
use xiom.convert;
use xiom.io;

var _n: Int = 0;

fn bump() {
  _n = _n + 1;
}

fn main() -> Int {
  io.println("P4 start");
  io.flush_stdout();
  var exec = executor.executor_new();
  executor.executor_spawn(&mut exec, bump);
  io.println("P4 spawned tasks=" + convert.int_to_string(executor.executor_tasks(&exec)));
  io.flush_stdout();
  executor.executor_run(&mut exec);
  io.println("P4 ran n=" + convert.int_to_string(_n));
  io.flush_stdout();
  0
}
