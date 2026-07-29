module smoke_time_stress
use xiom.time;

fn main() -> Int {
  var total = time.Duration.from_secs(0);
  var i: Int = 0;
  while i < 100 {
    total = total.add(time.Duration.from_millis(10));
    i = i + 1;
  }
  if total.as_millis() != 1000 { return 1; }
  return 0;
}
