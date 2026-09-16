// p_async_p5.xi -- stderr-marked executor probe (stderr is unbuffered).
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_async_p5
use xiom.async.executor;
use xiom.io.console;
use xiom.convert;
use xiom.io;

var _n: Int = 0;

fn bump() {
  _n = _n + 1;
}

fn main() -> Int {
  console.console_write_error("P5:start\n");
  var exec = executor.executor_new();
  console.console_write_error("P5:new\n");
  executor.executor_spawn(&mut exec, bump);
  console.console_write_error("P5:spawn\n");
  console.console_write_error("P5:tasks=" + convert.int_to_string(executor.executor_tasks(&exec)) + "\n");
  executor.executor_run(&mut exec);
  console.console_write_error("P5:ran n=" + convert.int_to_string(_n) + "\n");
  io.println("P5 OK");
  0
}
