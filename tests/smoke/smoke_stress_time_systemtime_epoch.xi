module smoke_stress_time_systemtime_epoch
use xiom.time;

fn main() -> Int {
  var epoch = time.SystemTime.unix_epoch();
  var secs = epoch.secs_since_epoch();
  if secs >= 0 { return 0; } else { return 1; }
}
