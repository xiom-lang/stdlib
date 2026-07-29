module smoke_collections_vec_capacity
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].with_capacity(16);
  if v.len() != 0 { return 1; }

  var i: Int = 0;
  while i < 100 {
    v.push(i);
    i = i + 1;
  }
  if v.len() != 100 { return 2; }

  var j: Int = 0;
  while j < 100 {
    let item = v.get(j);
    match item {
      Some(x) => { if x != j { return 3; } },
      None => { return 4; },
    };
    j = j + 1;
  }

  return 0;
}
