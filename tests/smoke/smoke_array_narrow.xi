module smoke_array_narrow
use xiom.array;

fn main() -> Int {
  let arr = [1 as Int8, 2 as Int8, 3 as Int8];
  if array.len(&arr) != 3 { return 1; }
  match array.first(&arr) {
    Some(v) => { if *v != 1 as Int8 { return 2; } },
    None => { return 3; },
  };

  var arr16 = [100 as Int16, 200 as Int16];
  var mapped = array.map(arr16, fn(x: Int16) -> Int16 { return (x + 0 as Int16) as Int16; });
  if mapped[0] != 100 as Int16 { return 4; }

  return 0;
}
