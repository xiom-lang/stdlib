module smoke_collections_btree_set
use xiom.collections;

fn main() -> Int {
  var s = BTreeSet[Int].new();
  if s.len() != 0 { return 1; }

  s.insert(5);
  s.insert(2);
  s.insert(8);
  s.insert(1);
  if s.len() != 4 { return 2; }

  if !s.contains(5) { return 3; }
  if s.contains(99) { return 4; }

  if !s.insert(3) { return 5; }
  if s.insert(3) { return 6; }
  if s.len() != 5 { return 7; }

  match s.first() {
    Some(x) => { if x != 1 { return 8; } },
    None => { return 9; },
  };
  match s.last() {
    Some(x) => { if x != 8 { return 10; } },
    None => { return 11; },
  };

  if !s.remove(3) { return 12; }
  if s.remove(99) { return 13; }
  if s.contains(3) { return 14; }
  if s.len() != 4 { return 15; }

  return 0;
}
