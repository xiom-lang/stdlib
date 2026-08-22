module smoke_array_edge
use xiom.array;

fn main() -> Int {
  let arr = [1, 2, 3];
  var i: Int = 0;
  while i < 3 {
    match array.get(&arr, i) {
      Some(v) => { if v != i + 1 { return 1; } },
      None => { return 2; },
    };
    i = i + 1;
  }

  match array.binary_search(&arr, &0) {
    Ok(_) => { return 3; },
    Err(i) => { if i != 0 { return 4; } },
  };

  match array.binary_search(&arr, &99) {
    Ok(_) => { return 5; },
    Err(i) => { if i != 3 { return 6; } },
  };

  return 0;
}
