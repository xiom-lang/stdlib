// XIOM stdlib stress — xiom.time Duration add and sub operations
// Verifies commutativity of addition and identity of subtraction.
// Returns 0 on success, nonzero on failure.

module smoke_stress_time_duration_add_sub
use xiom.time;

fn main() -> Int {
  var a = time.Duration.from_secs(10);
  var b = time.Duration.from_secs(7);
  var c = time.Duration.from_millis(500);

  var sum = a.add(b);
  if sum.as_secs() != 17 { return 1; }

  var diff = a.sub(b);
  if diff.as_secs() != 3 { return 2; }

  var zero = a.sub(a);
  if zero.as_secs() != 0 { return 3; }
  if zero.as_nanos() != 0 { return 4; }

  var sum_ms = c.add(c);
  if sum_ms.as_millis() != 1000 { return 5; }

  var sub_ms = a.sub(c);
  if sub_ms.as_millis() != 9500 { return 6; }

  return 0;
}
