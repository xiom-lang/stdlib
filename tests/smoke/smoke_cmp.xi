// XIOM stdlib smoke test -- xiom.cmp
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_cmp
use xiom.cmp;

fn main() -> Int {
  if cmp.max(10, 20) == 20 && cmp.min(10, 20) == 10 && cmp.clamp(5, 0, 10) == 5 {
    return 0;
  }
  return 1;
}
