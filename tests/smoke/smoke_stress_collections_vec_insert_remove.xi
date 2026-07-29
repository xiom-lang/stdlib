// XIOM stdlib stress — Vec insert and remove at positions
// Tests middle and end insertion/removal in a Vec.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vec_insert_remove
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(1);
  v.push(3);
  v.push(5);
  v.insert(1, 2);
  if v.len() != 4 { return 1; }
  if v[0] != 1 { return 2; }
  if v[1] != 2 { return 3; }
  if v[2] != 3 { return 4; }
  if v[3] != 5 { return 5; }
  v.insert(0, 0);
  if v[0] != 0 { return 6; }
  if v.len() != 5 { return 7; }
  var removed = v.remove(2);
  if v.len() != 4 { return 8; }
  if v[0] != 0 { return 9; }
  if v[1] != 1 { return 10; }
  if v[2] != 3 { return 11; }
  v.remove(0);
  if v[0] != 1 { return 12; }
  v.remove(v.len() - 1);
  if v.len() != 2 { return 13; }
  if v[0] != 1 { return 14; }
  if v[1] != 3 { return 15; }
  return 0;
}
