// XIOM stdlib stress -- Vec get out-of-bounds via .get()
// Uses safe .get() on out-of-bounds indices, expects None.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vec_get_oob
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(1);
  v.push(2);
  v.push(3);
  match v.get(3) {
    Some(_) => { return 1; }
    None => { }
  }
  match v.get(100) {
    Some(_) => { return 2; }
    None => { }
  }
  return 0;
}
