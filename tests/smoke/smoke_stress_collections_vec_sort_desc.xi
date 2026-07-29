// XIOM stdlib stress — Vec sort with negative and positive values
// Pushes mixed-sign values, sorts, verifies correct order.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vec_sort_desc
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(5);
  v.push(-3);
  v.push(0);
  v.push(-10);
  v.push(7);
  v.sort();
  if v[0] != -10 { return 1; }
  if v[1] != -3 { return 2; }
  if v[2] != 0 { return 3; }
  if v[3] != 5 { return 4; }
  if v[4] != 7 { return 5; }
  return 0;
}
