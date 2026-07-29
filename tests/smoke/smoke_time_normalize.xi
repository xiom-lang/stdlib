module smoke_time_normalize
use xiom.time;

fn main() -> Int {
  var d1 = time.Duration.new(1, 1500000000);
  if d1.as_secs() != 2 { return 1; }

  var d2 = time.Duration.new(2, -500000000);
  if d2.subsec_nanos() >= 0 { return 2; }

  return 0;
}
