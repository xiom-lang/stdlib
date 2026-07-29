// XIOM stdlib stress — xiom.time Duration factory and conversion methods
// Tests from_secs, from_millis, from_micros, from_nanos and as_* round-trips.
// Returns 0 on success, nonzero on failure.

module smoke_stress_time_duration_conversions
use xiom.time;

fn main() -> Int {
  var ds = time.Duration.from_secs(3);
  var dm = time.Duration.from_millis(5000);
  var du = time.Duration.from_micros(1_000_000);
  var dn = time.Duration.from_nanos(1_000_000_000);

  if ds.as_secs() != 3 { return 1; }
  if ds.as_millis() != 3000 { return 2; }
  if ds.as_micros() != 3_000_000 { return 3; }
  if ds.as_nanos() != 3_000_000_000 { return 4; }

  if dm.as_secs() != 5 { return 5; }
  if dm.as_millis() != 5000 { return 6; }

  if du.as_secs() != 1 { return 7; }
  if du.as_micros() != 1_000_000 { return 8; }

  if dn.as_secs() != 1 { return 9; }
  if dn.as_nanos() != 1_000_000_000 { return 10; }

  return 0;
}
