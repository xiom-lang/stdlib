module smoke_time_duration_new
use xiom.time;

fn main() -> Int {
  var d = time.Duration.new(5, 500000000);
  if d.as_secs() != 5 { return 1; }
  if d.subsec_nanos() != 500000000 { return 2; }

  var d2 = time.Duration.new(0, 0);
  if d2.as_secs() != 0 { return 3; }
  if d2.subsec_nanos() != 0 { return 4; }

  return 0;
}
