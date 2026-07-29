module smoke_time_edge
use xiom.time;

fn main() -> Int {
  var d0 = time.Duration.from_secs(0);
  if d0.as_secs() != 0 { return 1; }
  if d0.as_nanos() != 0 { return 2; }

  var d1 = time.Duration.new(1, 1500000000);
  if d1.as_secs() != 2 { return 3; }
  if d1.subsec_nanos() != 500000000 { return 4; }

  return 0;
}
