module smoke_array_slice
use xiom.array;

fn main() -> Int {
  let arr = [1, 2, 3, 4, 5];
  var s = array.as_slice(&arr);
  if s.len() != 5 { return 1; }

  return 0;
}
