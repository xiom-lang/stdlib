// XIOM stdlib stress -- xiom.time DateTime component accessors
// Verifies month in [1,12], day in [1,31], hour in [0,23],
// minute in [0,59], second in [0,59]. All within valid ranges.
// Returns 0 on success, nonzero on failure.

module smoke_stress_time_datetime_components
use xiom.time;

fn main() -> Int {
  var dt = time.DateTime.now();

  if dt.month() < 1 || dt.month() > 12 { return 1; }
  if dt.day() < 1 || dt.day() > 31 { return 2; }
  if dt.hour() < 0 || dt.hour() > 23 { return 3; }
  if dt.minute() < 0 || dt.minute() > 59 { return 4; }
  if dt.second() < 0 || dt.second() > 59 { return 5; }

  return 0;
}
