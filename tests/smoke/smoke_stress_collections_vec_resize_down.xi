// XIOM stdlib stress -- Vec shrink via pop then refill
// Fills vec, pops all, refills, verifies data integrity.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vec_resize_down
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  var i = 0;
  while i < 100 {
    v.push(i);
    i = i + 1;
  }
  i = 0;
  while i < 100 {
    var _ = v.pop();
    i = i + 1;
  }
  if v.len() != 0 { return 1; }
  if not v.is_empty() { return 2; }
  v.push(42);
  v.push(99);
  if v.len() != 2 { return 3; }
  if v[0] != 42 { return 4; }
  if v[1] != 99 { return 5; }
  return 0;
}
