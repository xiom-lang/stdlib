module smoke_array_contains
use xiom.array;

fn main() -> Int {
  let arr = [10, 20, 30, 40, 50];
  if !array.contains(&arr, &20) { return 1; }
  if !array.contains(&arr, &50) { return 2; }
  if array.contains(&arr, &99) { return 3; }
  if array.contains(&arr, &0) { return 4; }

  return 0;
}
