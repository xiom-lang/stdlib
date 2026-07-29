// XIOM stdlib stress — Vec pop
// Pushes items, pops them, verifies LIFO order and empty state.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vec_pop
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(10);
  v.push(20);
  v.push(30);
  if v.len() != 3 { return 1; }
  match v.pop() {
    Some(x) => { if x != 30 { return 2; } }
    None => { return 3; }
  }
  match v.pop() {
    Some(x) => { if x != 20 { return 4; } }
    None => { return 5; }
  }
  match v.pop() {
    Some(x) => { if x != 10 { return 6; } }
    None => { return 7; }
  }
  match v.pop() {
    Some(_) => { return 8; }
    None => { return 0; }
  }
}
