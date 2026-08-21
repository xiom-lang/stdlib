// XIOM stdlib stress -- Map contains
// Tests contains for existing and missing keys.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_map_contains
use xiom.collections;

fn main() -> Int {
  var m = Map[Str, Int].new();
  m.insert("alpha", 1);
  m.insert("beta", 2);
  m.insert("gamma", 3);
  if not m.contains("alpha") { return 1; }
  if not m.contains("beta") { return 2; }
  if not m.contains("gamma") { return 3; }
  if m.contains("delta") { return 4; }
  if m.contains("") { return 5; }
  return 0;
}
