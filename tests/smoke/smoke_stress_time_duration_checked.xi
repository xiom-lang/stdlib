module smoke_stress_time_duration_checked
use xiom.time;

fn main() -> Int {
  var d1 = time.Duration.from_secs(100);
  var d2 = time.Duration.from_secs(200);
  match d1.checked_add(d2) {
    Some(result) => {
      if result.as_secs() == 300 { return 0; } else { return 2; }
    }
    None => { return 1; }
  }
}
