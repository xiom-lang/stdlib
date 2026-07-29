module smoke_array_stress
use xiom.array;

fn main() -> Int {
  var arr = [5, 3, 1, 4, 2, 8, 6, 7, 0, 9];
  array.sort(&mut arr);

  var i: Int = 0;
  while i < 10 {
    if arr[i] != i { return 1; }
    i = i + 1;
  }

  return 0;
}
