module smoke_collections_vec_insert_remove
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(10);
  v.push(30);

  v.insert(1, 20);
  if v.len() != 3 { return 1; }
  let g1 = v.get(1);
  match g1 {
    Some(x) => { if x != 20 { return 2; } },
    None => { return 3; },
  };

  v.insert(0, 5);
  if v.len() != 4 { return 4; }
  let g0 = v.get(0);
  match g0 {
    Some(x) => { if x != 5 { return 5; } },
    None => { return 6; },
  };

  let rem = v.remove(2);
  match rem {
    Some(x) => { if x != 20 { return 7; } },
    None => { return 8; },
  };
  if v.len() != 3 { return 9; }

  let rem_neg = v.remove(-1);
  match rem_neg {
    Some(_) => { return 10; },
    None => {},
  };

  let rem_oom = v.remove(999);
  match rem_oom {
    Some(_) => { return 11; },
    None => {},
  };

  return 0;
}
