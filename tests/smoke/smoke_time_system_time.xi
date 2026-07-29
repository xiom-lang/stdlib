module smoke_time_system_time
use xiom.time;

fn main() -> Int {
  var st = time.SystemTime.now();
  if st.secs_since_epoch() > 0 { return 0; }

  var unix = time.SystemTime.unix_epoch();
  if unix.secs_since_epoch() == 0 { return 0; }

  return 1;
}
