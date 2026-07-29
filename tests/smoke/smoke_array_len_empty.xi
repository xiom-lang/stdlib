module smoke_array_len_empty
use xiom.array;

fn main() -> Int {
  let arr5 = [1, 2, 3, 4, 5];
  if array.len(&arr5) != 5 { return 1; }
  if array.is_empty(&arr5) { return 2; }

  let empty: [0]Int;
  if array.len(&empty) != 0 { return 3; }
  if !array.is_empty(&empty) { return 4; }

  return 0;
}
