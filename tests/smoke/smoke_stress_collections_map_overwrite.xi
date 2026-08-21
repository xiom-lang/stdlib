// XIOM stdlib stress -- Map overwrite existing key
// Inserts a key, overwrites it with new value, verifies update.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_map_overwrite
use xiom.collections;

fn main() -> Int {
  var m = Map[Int, Int].new();
  m.insert(1, 100);
  m.insert(1, 200);
  m.insert(1, 300);
  if m.len() != 1 { return 1; }
  match m.get(1) {
    Some(v) => { if v != 300 { return 2; } }
    None => { return 3; }
  }
  m.insert(2, 400);
  m.insert(2, 500);
  if m.len() != 2 { return 4; }
  match m.get(2) {
    Some(v) => { if v != 500 { return 5; } }
    None => { return 6; }
  }
  return 0;
}
