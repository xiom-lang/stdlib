// XIOM stdlib smoke test — xiom.core
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_core
use xiom.core;

fn main() -> Int {
  let a = [1, 2, 3, 4, 5];
  let b = [1, 2, 3, 4, 5];
  if core.is_sorted(a) && core.contains(b, 3) {
    return 0;
  }
  return 1;
}
