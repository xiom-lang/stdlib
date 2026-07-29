module smoke_time_duration_as
use xiom.time;

fn main() -> Int {
  var d = time.Duration.new(2, 500000000);

  if d.as_secs() != 2 { return 1; }
  if d.as_millis() != 2500 { return 2; }
  if d.as_micros() != 2500000 { return 3; }
  if d.as_nanos() != 2500000000 { return 4; }

  var f = d.as_secs_f64();
  if f < 2.49 || f > 2.51 { return 5; }

  return 0;
}
