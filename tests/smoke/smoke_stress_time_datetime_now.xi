// XIOM stdlib stress -- xiom.time DateTime.now returns a valid DateTime
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// DateTime.now() must return a value whose year is >= 2025.
// Returns 0 on success, nonzero on failure.

module smoke_stress_time_datetime_now
use xiom.time;

fn main() -> Int {
  var dt = time.DateTime.now();
  if dt.year() >= 2025 { return 0; } else { return 1; }
}
