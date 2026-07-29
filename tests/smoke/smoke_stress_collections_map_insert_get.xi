// XIOM stdlib stress — Map insert and get
// Inserts key-value pairs and retrieves them.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_map_insert_get
use xiom.collections;

fn main() -> Int {
  var m = Map[Int, Int].new();
  m.insert(1, 10);
  m.insert(2, 20);
  m.insert(3, 30);
  match m.get(1) {
    Some(v) => { if v != 10 { return 1; } }
    None => { return 2; }
  }
  match m.get(2) {
    Some(v) => { if v != 20 { return 3; } }
    None => { return 4; }
  }
  match m.get(3) {
    Some(v) => { if v != 30 { return 5; } }
    None => { return 6; }
  }
  if m.len() != 3 { return 7; }
  return 0;
}
