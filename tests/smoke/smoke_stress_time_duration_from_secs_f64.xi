// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_time_duration_from_secs_f64
use xiom.time;

fn main() -> Int {
  var d = time.Duration.from_secs_f64(3.5);
  if d.as_secs() >= 3 { return 0; } else { return 1; }
}
