// XIOM stdlib stress -- Vec push large (1000 elements)
// Pushes 1000 ints and verifies length.
// Returns 0 on success.

module smoke_stress_collections_vec_push_large
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  var i = 0;
  while i < 1000 {
    v.push(i);
    i = i + 1;
  }
  if v.len() == 1000 { return 0; } else { return 1; }
}
