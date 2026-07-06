// XIOM stdlib smoke test — xiom.array
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_array
use xiom.array;

fn main() -> Int {
  let arr = [10, 20, 30, 40, 50];
  if array.len(&arr) == 5 && array.contains(&arr, &30) {
    return 0;
  }
  return 1;
}
