module smoke_sort
use xiom.sort;
use xiom.cmp;
fn main() -> Int {
  var v = Vec[Int].new();
  v.push(5); v.push(2); v.push(4); v.push(1); v.push(3);
  xiom.sort.sort_quick(&v);
  if !(v[0] == 1 && v[1] == 2 && v[2] == 3 && v[3] == 4 && v[4] == 5) { return 1; }
  if !xiom.sort.is_sorted(&v) { return 1; }
  var w = Vec[Int].new();
  w.push(9); w.push(8); w.push(7);
  xiom.sort.sort_merge(&w);
  if !(w[0] == 7 && w[1] == 8 && w[2] == 9) { return 1; }
  return 0;
}
