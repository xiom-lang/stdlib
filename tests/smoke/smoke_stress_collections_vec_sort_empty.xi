// XIOM stdlib stress — Vec sort on empty and single-element
// Verifies sort does not crash on empty or single-element vectors.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vec_sort_empty
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.sort();
  if v.len() != 0 { return 1; }
  v.push(42);
  v.sort();
  if v.len() != 1 { return 2; }
  if v[0] != 42 { return 3; }
  return 0;
}
