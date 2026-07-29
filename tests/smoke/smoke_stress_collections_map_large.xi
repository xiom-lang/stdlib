// XIOM stdlib stress — Map large (200 entries)
// Inserts 200 key-value pairs via while loop and verifies count.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_map_large
use xiom.collections;

fn main() -> Int {
  var m = Map[Int, Int].new();
  var i = 0;
  while i < 200 {
    m.insert(i, i * 2);
    i = i + 1;
  }
  if m.len() != 200 { return 1; }
  match m.get(0) {
    Some(v) => { if v != 0 { return 2; } }
    None => { return 3; }
  }
  match m.get(199) {
    Some(v) => { if v != 398 { return 4; } }
    None => { return 5; }
  }
  match m.get(100) {
    Some(v) => { if v != 200 { return 6; } }
    None => { return 7; }
  }
  return 0;
}
