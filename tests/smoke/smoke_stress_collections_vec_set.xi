// XIOM stdlib stress — Vec set
// Sets elements at various indices and verifies values.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vec_set
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(1);
  v.push(2);
  v.push(3);
  v.set(0, 10);
  v.set(1, 20);
  v.set(2, 30);
  if v[0] != 10 { return 1; }
  if v[1] != 20 { return 2; }
  if v[2] != 30 { return 3; }
  return 0;
}
