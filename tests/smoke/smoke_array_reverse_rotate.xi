module smoke_array_reverse_rotate
use xiom.array;

fn main() -> Int {
  var arr = [1, 2, 3, 4, 5];
  array.reverse(&mut arr);
  if arr[0] != 5 { return 1; }
  if arr[4] != 1 { return 2; }

  var arr2 = [1, 2, 3, 4, 5];
  array.rotate_left(&mut arr2, 2);
  if arr2[0] != 3 { return 3; }
  if arr2[1] != 4 { return 4; }
  if arr2[2] != 5 { return 5; }
  if arr2[3] != 1 { return 6; }
  if arr2[4] != 2 { return 7; }

  var arr3 = [1, 2, 3, 4, 5];
  array.rotate_right(&mut arr3, 1);
  if arr3[0] != 5 { return 8; }
  if arr3[1] != 1 { return 9; }

  return 0;
}
