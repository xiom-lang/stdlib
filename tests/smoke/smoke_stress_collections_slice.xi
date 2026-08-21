// XIOM stdlib stress -- Slice first and last access
// Tests slice boundary access on a Vec-derived slice.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_slice
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(11);
  v.push(22);
  v.push(33);
  match v.first() {
    Some(x) => { if x != 11 { return 1; } }
    None => { return 2; }
  }
  match v.last() {
    Some(x) => { if x != 33 { return 3; } }
    None => { return 4; }
  }
  var empty = Vec[Int].new();
  match empty.first() {
    Some(_) => { return 5; }
    None => { }
  }
  match empty.last() {
    Some(_) => { return 6; }
    None => { }
  }
  return 0;
}
