// XIOM stdlib stress -- BTreeMap insert, get, contains, remove
// Tests ordered map operations with sorted key ordering.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_btreemap
use xiom.collections;

fn main() -> Int {
  var bm = BTreeMap[Int, Str].new();
  bm.insert(3, "three");
  bm.insert(1, "one");
  bm.insert(2, "two");
  if bm.len() != 3 { return 1; }
  if not bm.contains(1) { return 2; }
  if not bm.contains(2) { return 3; }
  if not bm.contains(3) { return 4; }
  if bm.contains(4) { return 5; }
  match bm.get(1) {
    Some(v) => { if v != "one" { return 6; } }
    None => { return 7; }
  }
  match bm.get(2) {
    Some(v) => { if v != "two" { return 8; } }
    None => { return 9; }
  }
  match bm.get(3) {
    Some(v) => { if v != "three" { return 10; } }
    None => { return 11; }
  }
  bm.remove(2);
  if bm.len() != 2 { return 12; }
  if bm.contains(2) { return 13; }
  match bm.get(2) {
    Some(_) => { return 14; }
    None => { }
  }
  bm.insert(1, "ONE");
  match bm.get(1) {
    Some(v) => { if v != "ONE" { return 15; } }
    None => { return 16; }
  }
  return 0;
}
