// XIOM stdlib stress — xiom.time Duration subtraction resulting in negative
// Duration sub should handle results where earlier > later (negative duration).
// Returns 0 on success, nonzero on failure.

module smoke_stress_time_duration_negative
use xiom.time;

fn main() -> Int {
  var small = time.Duration.from_secs(1);
  var large = time.Duration.from_secs(100);

  var neg = small.sub(large);
  if neg.as_secs() >= 0 { return 1; }

  var also_neg = time.Duration.from_millis(1).sub(time.Duration.from_secs(1));
  if also_neg.as_millis() >= 0 { return 2; }

  var zero = neg.add(large.sub(small));
  if zero.as_nanos() != 0 { return 3; }

  return 0;
}
