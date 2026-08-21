// XIOM stdlib stress -- Set insert, contains, remove, intersection, union, diff
// Tests Set basic operations and set algebra.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_set_ops
use xiom.collections;

fn main() -> Int {
  var s = Set[Int].new();
  s.insert(1);
  s.insert(2);
  s.insert(3);
  if s.len() != 3 { return 1; }
  if not s.contains(1) { return 2; }
  if not s.contains(2) { return 3; }
  if not s.contains(3) { return 4; }
  s.remove(2);
  if s.contains(2) { return 5; }
  if s.len() != 2 { return 6; }
  var s2 = Set[Int].new();
  s2.insert(3);
  s2.insert(4);
  var inter = s.intersection(s2);
  if inter.len() != 1 { return 7; }
  if not inter.contains(3) { return 8; }
  var uni = s.union(s2);
  if uni.len() != 3 { return 9; }
  var diff = s.difference(s2);
  if diff.len() != 1 { return 10; }
  if not diff.contains(1) { return 11; }
  return 0;
}
