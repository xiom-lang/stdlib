// XIOM stdlib stress — Map empty operations
// Tests operations on empty map: get, contains, len, keys, values, clear.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_map_empty
use xiom.collections;

fn main() -> Int {
  var m = Map[Int, Int].new();
  if m.len() != 0 { return 1; }
  if m.contains(0) { return 2; }
  match m.get(0) {
    Some(_) => { return 3; }
    None => { }
  }
  var ks = m.keys();
  if ks.len() != 0 { return 4; }
  var vs = m.values();
  if vs.len() != 0 { return 5; }
  m.clear();
  if m.len() != 0 { return 6; }
  return 0;
}
