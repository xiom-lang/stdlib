module smoke_search
use xiom.search;
fn main() -> Int {
  var v = Vec[Int].new();
  v.push(1); v.push(2); v.push(3); v.push(4); v.push(5);
  var r = xiom.search.binary_search(&v, &3);
  match r {
    Some(i) => { if i != 2 { return 1; } }
    None => { return 1; }
  }
  if xiom.search.lower_bound(&v, &3) != 2 { return 1; }
  if xiom.search.upper_bound(&v, &3) != 3 { return 1; }
  return 0;
}
