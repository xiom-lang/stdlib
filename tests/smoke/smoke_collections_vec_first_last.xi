module smoke_collections_vec_first_last
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();

  let f_empty = v.first();
  match f_empty {
    Some(_) => { return 1; },
    None => {},
  };

  let l_empty = v.last();
  match l_empty {
    Some(_) => { return 2; },
    None => {},
  };

  v.push(10);
  let f1 = v.first();
  match f1 {
    Some(x) => { if x != 10 { return 3; } },
    None => { return 4; },
  };
  let l1 = v.last();
  match l1 {
    Some(x) => { if x != 10 { return 5; } },
    None => { return 6; },
  };

  v.push(20);
  v.push(30);
  v.push(40);

  let f4 = v.first();
  match f4 {
    Some(x) => { if x != 10 { return 7; } },
    None => { return 8; },
  };
  let l4 = v.last();
  match l4 {
    Some(x) => { if x != 40 { return 9; } },
    None => { return 10; },
  };

  return 0;
}
