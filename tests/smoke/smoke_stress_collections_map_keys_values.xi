// XIOM stdlib stress — Map keys and values
// Verifies keys() and values() return correct collections.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_map_keys_values
use xiom.collections;

fn main() -> Int {
  var m = Map[Int, Str].new();
  m.insert(1, "a");
  m.insert(2, "b");
  m.insert(3, "c");
  var ks = m.keys();
  if ks.len() != 3 { return 1; }
  var vs = m.values();
  if vs.len() != 3 { return 2; }
  return 0;
}
