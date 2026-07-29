// XIOM stdlib stress — Vec sort ascending
// Pushes unsorted values, sorts, verifies ascending order.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vec_sort_asc
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(30);
  v.push(10);
  v.push(20);
  v.push(50);
  v.push(40);
  v.sort();
  if v[0] != 10 { return 1; }
  if v[1] != 20 { return 2; }
  if v[2] != 30 { return 3; }
  if v[3] != 40 { return 4; }
  if v[4] != 50 { return 5; }
  return 0;
}
