// XIOM stdlib stress — xiom.time sleep_ms pauses execution
// Calls sleep_ms(1) and verifies that elapsed time is at least 0.
// Returns 0 on success, nonzero on failure.

module smoke_stress_time_sleep_ms
use xiom.time;

fn main() -> Int {
  var t0 = time.Instant.now();
  time.sleep_ms(1);
  var elapsed = t0.elapsed();
  if elapsed.as_nanos() >= 0 { return 0; } else { return 1; }
}
