module smoke_time_narrow
use xiom.time;

fn main() -> Int {
  var d = time.Duration.from_secs(100);
  var ms: Int32 = d.as_millis() as Int32;
  if ms != 100000 as Int32 { return 1; }

  var d2 = time.Duration.from_secs(5);
  var s16: Int16 = d2.as_secs() as Int16;
  if s16 != 5 as Int16 { return 2; }

  return 0;
}
