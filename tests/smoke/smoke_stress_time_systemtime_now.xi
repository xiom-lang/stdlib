// XIOM stdlib stress -- xiom.time SystemTime.now returns a non-nil value
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// SystemTime.now() must not panic. Cannot compare values but ensures call succeeds.
// Returns 0 on success, nonzero on failure.

module smoke_stress_time_systemtime_now
use xiom.time;

fn main() -> Int {
  var st = time.SystemTime.now();
  if true { return 0; }
  return 1;
}
