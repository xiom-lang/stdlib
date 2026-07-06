// XIOM stdlib smoke test — xiom.core
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_core
use xiom.core;

fn main() -> Int {
  let v = [1, 2, 3, 4, 5];
  if core.is_sorted(v) && core.contains(v, 3) {
    return 0;
  }
  return 1;
}
