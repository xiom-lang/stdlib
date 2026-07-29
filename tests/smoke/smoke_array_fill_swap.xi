module smoke_array_fill_swap
use xiom.array;

fn main() -> Int {
  var arr = [0, 0, 0, 0, 0];
  array.fill(&mut arr, 42);
  if arr[0] != 42 { return 1; }
  if arr[2] != 42 { return 2; }
  if arr[4] != 42 { return 3; }

  array.swap(&mut arr, 0, 4);
  if arr[0] != 42 { return 4; }
  if arr[4] != 42 { return 5; }

  var arr2 = [1, 2];
  array.swap(&mut arr2, 0, 1);
  if arr2[0] != 2 { return 6; }
  if arr2[1] != 1 { return 7; }

  return 0;
}
