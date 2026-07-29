module smoke_time_duration_checked
use xiom.time;

fn main() -> Int {
  var d1 = time.Duration.from_secs(10);
  var d2 = time.Duration.from_secs(3);

  match d1.checked_add(d2) {
    Some(d) => { if d.as_secs() != 13 { return 1; } },
    None => { return 2; },
  };

  match d1.checked_sub(d2) {
    Some(d) => { if d.as_secs() != 7 { return 3; } },
    None => { return 4; },
  };

  match d2.checked_sub(d1) {
    Some(_) => { return 5; },
    None => {},
  };

  return 0;
}
