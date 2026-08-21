// XIOM stdlib stress -- xiom.time Duration.new with various secs/nanos combos
// Returns 0 on success, nonzero on failure.

module smoke_stress_time_duration_new
use xiom.time;

fn main() -> Int {
  var d1 = time.Duration.new(0, 0);
  var d2 = time.Duration.new(1, 0);
  var d3 = time.Duration.new(0, 500_000_000);
  var d4 = time.Duration.new(2, 250_000_000);

  if d1.as_secs() == 0 && d1.as_nanos() == 0 &&
     d2.as_secs() == 1 && d2.as_nanos() == 1_000_000_000 &&
     d3.as_secs() == 0 && d3.as_nanos() == 500_000_000 &&
     d4.as_secs() == 2 && d4.as_nanos() == 2_250_000_000 {
    return 0;
  }
  return 1;
}
