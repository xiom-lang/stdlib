module smoke_time_duration_from
use xiom.time;

fn main() -> Int {
  var d1 = time.Duration.from_secs(10);
  if d1.as_secs() != 10 { return 1; }

  var d2 = time.Duration.from_millis(5000);
  if d2.as_secs() != 5 { return 2; }

  var d3 = time.Duration.from_micros(3000000);
  if d3.as_secs() != 3 { return 3; }

  var d4 = time.Duration.from_nanos(2000000000);
  if d4.as_secs() != 2 { return 4; }

  return 0;
}
