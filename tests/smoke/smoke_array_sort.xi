module smoke_array_sort
use xiom.array;

fn main() -> Int {
  var arr = [5, 3, 1, 4, 2];
  array.sort(&mut arr);
  if arr[0] != 1 { return 1; }
  if arr[1] != 2 { return 2; }
  if arr[2] != 3 { return 3; }
  if arr[3] != 4 { return 4; }
  if arr[4] != 5 { return 5; }

  return 0;
}
