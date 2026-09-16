// p_async_min.xi -- minimal async import probe.
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_async_min
use xiom.async.executor;
use xiom.async.channel;
use xiom.async.timer;
use xiom.io;

var _n: Int = 0;

fn bump() {
  _n = _n + 1;
}

fn main() -> Int {
  io.println("p_async_min start");
  io.flush_stdout();
  var exec = executor.executor_new();
  executor.executor_spawn(&mut exec, bump);
  executor.executor_run(&mut exec);
  if _n != 1 { io.println("one"); return 1; };
  io.println("p_async_min OK");
  io.flush_stdout();
  0
}
