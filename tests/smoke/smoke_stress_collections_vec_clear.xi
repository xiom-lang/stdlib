// XIOM stdlib stress -- Vec clear
// Pushes items, clears, verifies empty and can reuse.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vec_clear
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(1);
  v.push(2);
  v.push(3);
  if v.len() != 3 { return 1; }
  v.clear();
  if v.len() != 0 { return 2; }
  if not v.is_empty() { return 3; }
  v.push(42);
  if v.len() != 1 { return 4; }
  if v[0] != 42 { return 5; }
  return 0;
}
