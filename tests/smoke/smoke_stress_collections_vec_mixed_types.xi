// XIOM stdlib stress — Vec mixed operations
// Interleaves push, pop, set, and get to stress internal state.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vec_mixed_types
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(10);
  v.push(20);
  v.push(30);
  v.set(1, 25);
  if v[1] != 25 { return 1; }
  match v.pop() {
    Some(x) => { if x != 30 { return 2; } }
    None => { return 3; }
  }
  v.push(40);
  v.push(50);
  v.set(0, 15);
  if v.len() != 4 { return 4; }
  if v[0] != 15 { return 5; }
  if v[1] != 25 { return 6; }
  if v[2] != 40 { return 7; }
  if v[3] != 50 { return 8; }
  return 0;
}
