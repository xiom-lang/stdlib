// XIOM stdlib stress -- Vec resize up via repeated growth
// Starts small, grows beyond initial capacity, verifies integrity.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vec_resize_up
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  var i = 0;
  while i < 500 {
    v.push(i);
    i = i + 1;
  }
  if v.len() != 500 { return 1; }
  i = 0;
  while i < 500 {
    if v[i] != i { return 2; }
    i = i + 1;
  }
  return 0;
}
