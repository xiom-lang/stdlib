module smoke_stress_time_duration_subsec
use xiom.time;

fn main() -> Int {
  var d = time.Duration.from_secs_f64(1.5);
  var nanos = d.subsec_nanos();
  if nanos >= 0 { return 0; } else { return 1; }
}
