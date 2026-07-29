module smoke_collections_vec_edge
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  match v.pop() { Some(_) => { return 1; }, None => {}, };
  match v.get(0) { Some(_) => { return 2; }, None => {}, };
  match v.get(-1) { Some(_) => { return 3; }, None => {}, };
  match v.get(2147483647) { Some(_) => { return 4; }, None => {}, };
  match v.first() { Some(_) => { return 5; }, None => {}, };
  match v.last() { Some(_) => { return 6; }, None => {}, };

  v.clear();
  if !v.is_empty() { return 7; }
  if v.len() != 0 { return 8; }

  v.push(42);
  v.clear();
  v.push(42);
  v.push(42);
  v.push(42);
  v.clear();
  v.push(1);
  var count: Int = 0;
  while count < 1000 {
    v.push(count);
    count = count + 1;
  }
  if v.len() != 1001 { return 9; }
  match v.last() {
    Some(x) => { if x != 999 { return 10; } },
    None => { return 11; },
  };

  return 0;
}
