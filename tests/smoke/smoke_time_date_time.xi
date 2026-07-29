module smoke_time_date_time
use xiom.time;

fn main() -> Int {
  var dt = time.DateTime.now();
  if dt.year() >= 2024 { return 0; }
  return 1;
}
