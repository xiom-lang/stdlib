// XIOM stdlib stress — Vec first and last access
// Tests first() and last() on populated and single-element vectors.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vec_first_last
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(42);
  match v.first() {
    Some(x) => { if x != 42 { return 1; } }
    None => { return 2; }
  }
  match v.last() {
    Some(x) => { if x != 42 { return 3; } }
    None => { return 4; }
  }
  v.push(99);
  match v.first() {
    Some(x) => { if x != 42 { return 5; } }
    None => { return 6; }
  }
  match v.last() {
    Some(x) => { if x != 99 { return 7; } }
    None => { return 8; }
  }
  v.clear();
  match v.first() {
    Some(_) => { return 9; }
    None => { }
  }
  match v.last() {
    Some(_) => { return 10; }
    None => { }
  }
  return 0;
}
