// XIOM stdlib stress — Vec is_empty
// Verifies is_empty returns true for new/cleared vec, false after push.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vec_is_empty
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  if not v.is_empty() { return 1; }
  v.push(1);
  if v.is_empty() { return 2; }
  v.clear();
  if not v.is_empty() { return 3; }
  return 0;
}
