module smoke_time_instant
use xiom.time;

fn main() -> Int {
  var now = time.Instant.now();
  var duration = now.elapsed();
  if duration.as_secs() >= 0 { return 0; }
  return 1;
}
