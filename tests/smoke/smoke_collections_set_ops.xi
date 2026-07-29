module smoke_collections_set_ops
use xiom.collections;

fn main() -> Int {
  var a = Set[Int].new();
  a.insert(1); a.insert(2); a.insert(3); a.insert(4);

  var b = Set[Int].new();
  b.insert(3); b.insert(4); b.insert(5); b.insert(6);

  var u = a.union(&b);
  if u.len() < 4 { return 1; }
  if u.len() > 8 { return 2; }
  if !u.contains(1) { return 3; }
  if !u.contains(6) { return 4; }

  var i = a.intersection(&b);
  if i.len() != 2 { return 5; }
  if !i.contains(3) { return 6; }
  if !i.contains(4) { return 7; }

  var d = a.difference(&b);
  if d.len() != 2 { return 8; }
  if !d.contains(1) { return 9; }
  if !d.contains(2) { return 10; }
  if d.contains(3) { return 11; }

  return 0;
}
