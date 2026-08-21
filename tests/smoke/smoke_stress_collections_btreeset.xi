// XIOM stdlib stress -- BTreeSet insert, contains, remove
// Tests ordered set operations with unique sorted elements.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_btreeset
use xiom.collections;

fn main() -> Int {
  var bs = BTreeSet[Int].new();
  bs.insert(30);
  bs.insert(10);
  bs.insert(20);
  if bs.len() != 3 { return 1; }
  if not bs.contains(10) { return 2; }
  if not bs.contains(20) { return 3; }
  if not bs.contains(30) { return 4; }
  if bs.contains(40) { return 5; }
  bs.insert(10);
  if bs.len() != 3 { return 6; }
  bs.remove(20);
  if bs.len() != 2 { return 7; }
  if bs.contains(20) { return 8; }
  bs.remove(10);
  bs.remove(30);
  if bs.len() != 0 { return 9; }
  return 0;
}
