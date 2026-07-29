module smoke_collections_vec_narrow
use xiom.collections;

fn main() -> Int {
  var v8 = Vec[Int8].new();
  v8.push(1 as Int8);
  v8.push(127 as Int8);
  v8.push(-128 as Int8);
  if v8.len() != 3 { return 1; }
  match v8.get(0) {
    Some(x) => { if x != 1 as Int8 { return 2; } },
    None => { return 3; },
  };

  var v16 = Vec[Int16].new();
  v16.push(30000 as Int16);
  v16.push(-30000 as Int16);
  if v16.len() != 2 { return 4; }
  match v16.pop() {
    Some(x) => { if x != -30000 as Int16 { return 5; } },
    None => { return 6; },
  };

  var v32 = Vec[Int32].new();
  v32.push(2000000000 as Int32);
  v32.push(-2000000000 as Int32);
  if v32.len() != 2 { return 7; }
  match v32.first() {
    Some(x) => { if x != 2000000000 as Int32 { return 8; } },
    None => { return 9; },
  };

  var v8b = Vec[Int8].new();
  match v8b.pop() {
    Some(_) => { return 10; },
    None => {},
  };

  return 0;
}
