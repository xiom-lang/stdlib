module smoke_time_duration_ops
use xiom.time;

fn main() -> Int {
  var d1 = time.Duration.from_secs(5);
  var d2 = time.Duration.from_secs(3);

  var add = d1.add(d2);
  if add.as_secs() != 8 { return 1; }

  var sub = d1.sub(d2);
  if sub.as_secs() != 2 { return 2; }

  var mul = d1.mul(2);
  if mul.as_secs() != 10 { return 3; }

  var div = d1.div(5);
  if div.as_secs() != 1 { return 4; }

  return 0;
}
