module smoke_collections_vec_clear
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(1);
  v.push(2);
  v.push(3);
  v.push(4);
  v.push(5);
  if v.len() != 5 { return 1; }

  v.clear();
  if v.len() != 0 { return 2; }
  if !v.is_empty() { return 3; }

  v.push(99);
  if v.len() != 1 { return 4; }
  let g = v.get(0);
  match g {
    Some(x) => { if x != 99 { return 5; } },
    None => { return 6; },
  };

  v.clear();
  v.clear();
  if !v.is_empty() { return 7; }

  return 0;
}
