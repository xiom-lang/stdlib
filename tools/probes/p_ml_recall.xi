// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_ml_recall
use xiom.math.machine_learning;
use xiom.io;
fn main() -> Int {
  var yt = Vec[Int].new(); yt.push(1); yt.push(0); yt.push(1);
  var yp = Vec[Int].new(); yp.push(1); yp.push(0); yp.push(0);
  var r = machine_learning.metric_recall(&yt, &yp);
  io.println("recall=" + r);
  if r < 0.49 || r > 0.51 { return 1; }
  return 0;
}
