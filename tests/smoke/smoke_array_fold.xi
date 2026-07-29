module smoke_array_fold
use xiom.array;

fn main() -> Int {
  let arr = [1, 2, 3, 4, 5];
  var sum = array.fold(arr, 0, fn(acc: Int, x: Int) -> Int { return acc + x; });
  if sum != 15 { return 1; }

  var prod = array.fold(arr, 1, fn(acc: Int, x: Int) -> Int { return acc * x; });
  if prod != 120 { return 2; }

  return 0;
}
