// p_async_p6.xi -- one spawn + run, assert task drain and side-effect.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_async_p6
use xiom.async.executor;
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
  if _n != 1 { io.println("P6 n=" + convert.int_to_string(_n)); return 3; };
  io.println("P6 OK");
  0
}
