// XIOM stdlib stress -- xiom.time DateTime.now returns a valid DateTime
// DateTime.now() must return a value whose year is >= 2025.
// Returns 0 on success, nonzero on failure.

module smoke_stress_time_datetime_now
use xiom.time;

fn main() -> Int {
  var dt = time.DateTime.now();
  if dt.year() >= 2025 { return 0; } else { return 1; }
}
