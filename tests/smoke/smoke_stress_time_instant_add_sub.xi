module smoke_stress_time_instant_add_sub
use xiom.time;

fn main() -> Int {
  var now = time.Instant.now();
  var dur = time.Duration.from_secs(10);
  var later = now.add(dur);
  var back = later.sub(dur);
  if back.as_secs_since_epoch() <= now.as_secs_since_epoch() + 1 { return 0; } else { return 1; }
}
