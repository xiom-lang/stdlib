module smoke_collections_vec_large
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  var i: Int = 0;
  while i < 1000 {
    v.push(i);
    i = i + 1;
  }
  if v.len() != 1000 { return 1; }

  var j: Int = 0;
  while j < 1000 {
    match v.get(j) {
      Some(x) => { if x != j { return 2; } },
      None => { return 3; },
    };
    j = j + 1;
  }

  var k: Int = 0;
  while k < 500 {
    v.pop();
    k = k + 1;
  }
  if v.len() != 500 { return 4; }
  match v.last() {
    Some(x) => { if x != 499 { return 5; } },
    None => { return 6; },
  };

  return 0;
}
