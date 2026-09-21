// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_time_duration_subsec
use xiom.time;

fn main() -> Int {
  var d = time.Duration.from_secs_f64(1.5);
  var nanos = d.subsec_nanos();
  if nanos >= 0 { return 0; } else { return 1; }
}
