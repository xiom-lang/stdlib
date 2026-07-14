// XIOM stdlib smoke test — xiom.math
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_math
use xiom.math;

fn main() -> Int {
  if math.abs_int(-42) == 42 && math.max_int(3, 9) == 9 && math.min_int(3, 9) == 3 {
    return 0;
  }
  return 1;
}
