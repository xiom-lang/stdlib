module smoke_stress_time_duration_mul_div
use xiom.time;

fn main() -> Int {
  var d1 = time.Duration.from_secs(10);
  var d2 = d1.mul(2);
  if d2.as_secs() == 20 { return 0; } else { return 1; }
}
