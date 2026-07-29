module smoke_time_compare
use xiom.time;

fn main() -> Int {
  var d1 = time.Duration.from_secs(10);
  var d2 = time.Duration.from_secs(5);

  if d1.as_secs() <= d2.as_secs() { return 1; }
  if d2.as_secs() >= d1.as_secs() { return 2; }

  return 0;
}
