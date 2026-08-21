// XIOM stdlib stress -- Map clear
// Inserts entries, clears map, verifies empty state.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_map_clear
use xiom.collections;

fn main() -> Int {
  var m = Map[Int, Int].new();
  m.insert(1, 10);
  m.insert(2, 20);
  m.insert(3, 30);
  if m.len() != 3 { return 1; }
  m.clear();
  if m.len() != 0 { return 2; }
  if m.contains(1) { return 3; }
  m.insert(5, 50);
  if m.len() != 1 { return 4; }
  match m.get(5) {
    Some(v) => { if v != 50 { return 5; } }
    None => { return 6; }
  }
  return 0;
}
