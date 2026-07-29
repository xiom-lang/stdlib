module smoke_collections_vec_push_pop
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  if v.len() != 0 { return 1; }
  if !v.is_empty() { return 2; }

  v.push(10);
  if v.len() != 1 { return 3; }
  if v.is_empty() { return 4; }

  v.push(20);
  v.push(30);
  if v.len() != 3 { return 5; }

  let item = v.pop();
  match item {
    Some(x) => { if x != 30 { return 6; } },
    None => { return 7; },
  };
  if v.len() != 2 { return 8; }

  v.pop();
  v.pop();
  if v.len() != 0 { return 9; }

  let empty_pop = v.pop();
  match empty_pop {
    Some(_) => { return 10; },
    None => {},
  };

  return 0;
}
