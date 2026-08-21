// XIOM stdlib stress -- Vec get at boundaries
// Tests indexing at first, last, and uses .get() for safe retrieval.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vec_get_boundary
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(100);
  v.push(200);
  v.push(300);
  if v[0] != 100 { return 1; }
  if v[2] != 300 { return 2; }
  match v.get(0) {
    Some(x) => { if x != 100 { return 3; } }
    None => { return 4; }
  }
  match v.get(2) {
    Some(x) => { if x != 300 { return 5; } }
    None => { return 6; }
  }
  return 0;
}
