// XIOM stdlib stress — xiom.time Instant.now returns non-trivial Instant
// Instant.now() must not panic and elapsed duration must be >= 0.
// Returns 0 on success, nonzero on failure.

module smoke_stress_time_instant_now
use xiom.time;

fn main() -> Int {
  var t0 = time.Instant.now();
  var d = t0.elapsed();
  if d.as_nanos() < 0 { return 1; }

  return 0;
}
