module smoke_stress_time_duration_from_secs_f64
use xiom.time;

fn main() -> Int {
  var d = time.Duration.from_secs_f64(3.5);
  if d.as_secs() >= 3 { return 0; } else { return 1; }
}
