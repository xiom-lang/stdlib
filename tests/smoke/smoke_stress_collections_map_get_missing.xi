// XIOM stdlib stress -- Map get missing key
// Tests .get() on keys not present in map, expects None.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_map_get_missing
use xiom.collections;

fn main() -> Int {
  var m = Map[Int, Str].new();
  m.insert(1, "one");
  m.insert(2, "two");
  match m.get(3) {
    Some(_) => { return 1; }
    None => { }
  }
  match m.get(0) {
    Some(_) => { return 2; }
    None => { }
  }
  match m.get(999) {
    Some(_) => { return 3; }
    None => { }
  }
  return 0;
}
