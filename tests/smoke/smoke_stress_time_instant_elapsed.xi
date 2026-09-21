// XIOM stdlib stress -- xiom.time Instant.elapsed monotonic growth
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Two calls to elapsed on the same Instant should return increasing values.
// Returns 0 on success, nonzero on failure.

module smoke_stress_time_instant_elapsed
use xiom.time;

fn main() -> Int {
  var t0 = time.Instant.now();
  var d1 = t0.elapsed();
  var d2 = t0.elapsed();
  if d2.as_nanos() < d1.as_nanos() { return 1; }

  var t1 = time.Instant.now();
  var dur = t1.duration_since(t0);
  if dur.as_nanos() < 0 { return 2; }

  return 0;
}
