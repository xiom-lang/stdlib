// XIOM stdlib stress -- Map remove
// Inserts keys, removes one, verifies it's gone and others remain.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_map_remove
use xiom.collections;

fn main() -> Int {
  var m = Map[Int, Str].new();
  m.insert(1, "one");
  m.insert(2, "two");
  m.insert(3, "three");
  m.remove(2);
  if m.len() != 2 { return 1; }
  if m.contains(2) { return 2; }
  if not m.contains(1) { return 3; }
  if not m.contains(3) { return 4; }
  m.remove(1);
  m.remove(3);
  if m.len() != 0 { return 5; }
  return 0;
}
