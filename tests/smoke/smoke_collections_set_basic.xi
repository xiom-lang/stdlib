module smoke_collections_set_basic
use xiom.collections;

fn main() -> Int {
  var s = Set[Int].new();
  if s.len() != 0 { return 1; }

  s.insert(1);
  s.insert(2);
  s.insert(3);
  if s.len() != 3 { return 2; }

  if !s.contains(1) { return 3; }
  if !s.contains(2) { return 4; }
  if s.contains(4) { return 5; }

  s.insert(2);
  if s.len() != 3 { return 6; }

  s.remove(2);
  if s.len() != 2 { return 7; }
  if s.contains(2) { return 8; }

  s.remove(99);
  if s.len() != 2 { return 9; }

  return 0;
}
