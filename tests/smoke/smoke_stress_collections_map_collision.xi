// XIOM stdlib stress — Map collision stress
// Inserts many entries with keys that may collide internally.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_map_collision
use xiom.collections;

fn main() -> Int {
  var m = Map[Int, Int].new();
  var i = 0;
  while i < 100 {
    m.insert(i, i * 10);
    i = i + 1;
  }
  if m.len() != 100 { return 1; }
  i = 0;
  while i < 100 {
    match m.get(i) {
      Some(v) => { if v != i * 10 { return 2; } }
      None => { return 3; }
    }
    i = i + 1;
  }
  return 0;
}
