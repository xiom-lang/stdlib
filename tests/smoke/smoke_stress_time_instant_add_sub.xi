module smoke_stress_time_instant_add_sub
use xiom.time.instant;
use xiom.time.duration;

fn main() -> Int {
  var now = instant.instant_now();
  var dur = duration.duration_secs(10);
  var later = instant.instant_add(now, dur);
  var back = instant.instant_sub(later, dur);
  if instant.instant_compare(back, now) <= 0 {
    return 0;
  }
  return 1;
}
