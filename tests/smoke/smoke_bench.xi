// NOTE: link/run smoke only
// XIOM stdlib smoke test -- xiom.bench
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_bench
use xiom.bench;

fn main() -> Int {
  if xiom.bench.black_box(42) == 42 {
    return 0;
  }
  return 1;
}
