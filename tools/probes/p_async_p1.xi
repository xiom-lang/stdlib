// p_async_p1.xi -- async imports only; does the process start?
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
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
