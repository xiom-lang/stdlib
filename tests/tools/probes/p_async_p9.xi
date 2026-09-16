// p_async_p9.xi -- 5000 spawns, drain, no side-effect assert.
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_async_p9
use xiom.async.executor;
use xiom.convert;
use xiom.io;

var _n: Int = 0;

fn bump() {
  _n = _n + 1;
}

fn main() -> Int {
  var exec = executor.executor_new();
  var i = 0;
  while i < 5000 {
    executor.executor_spawn(&mut exec, bump);
    i = i + 1;
  };
  if executor.executor_tasks(&exec) != 5000 { return 1; };
  executor.executor_run(&mut exec);
  if executor.executor_tasks(&exec) != 0 { return 2; };
  io.println("P9 n=" + convert.int_to_string(_n));
  0
}
