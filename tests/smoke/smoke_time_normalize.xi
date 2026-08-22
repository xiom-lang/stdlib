module smoke_time_normalize
use xiom.time;

fn main() -> Int {
  var d1 = time.Duration.new(1, 1500000000);
  if d1.as_secs() != 2 { return 1; }

  // Duration.new normalizes: negative nanos borrow from secs
  // (ensure: 0 <= result.nanos < NANOS_PER_SEC).
  var d2 = time.Duration.new(2, -500000000);
  if d2.as_secs() != 1 { return 2; }
  if d2.subsec_nanos() != 500000000 { return 3; }

  return 0;
}
