module smoke_time_duration_extreme
use xiom.time;

fn main() -> Int {
  var d0 = time.Duration.from_secs(0);
  if d0.as_secs() != 0 { return 1; }
  if d0.as_nanos() != 0 { return 2; }

  var d = time.Duration.from_secs(3600);
  if d.as_secs() != 3600 { return 3; }
  if d.as_millis() != 3600000 { return 4; }

  var d2 = time.Duration.from_millis(25);
  if d2.as_millis() != 25 { return 5; }

  var sum = d0.add(d2);
  if sum.as_millis() != 25 { return 6; }

  return 0;
}
