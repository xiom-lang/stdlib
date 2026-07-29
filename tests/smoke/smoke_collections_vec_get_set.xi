module smoke_collections_vec_get_set
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(100);
  v.push(200);
  v.push(300);

  let g0 = v.get(0);
  match g0 {
    Some(x) => { if x != 100 { return 1; } },
    None => { return 2; },
  };

  let g2 = v.get(2);
  match g2 {
    Some(x) => { if x != 300 { return 3; } },
    None => { return 4; },
  };

  let g_neg = v.get(-1);
  match g_neg {
    Some(_) => { return 5; },
    None => {},
  };

  let g_oom = v.get(999);
  match g_oom {
    Some(_) => { return 6; },
    None => {},
  };

  v.set(1, 222);
  let g1 = v.get(1);
  match g1 {
    Some(x) => { if x != 222 { return 7; } },
    None => { return 8; },
  };

  return 0;
}
