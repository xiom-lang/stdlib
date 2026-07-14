// XIOM stdlib smoke test — xiom.iter
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_iter
use xiom.iter;

fn main() -> Int {
  if iter.range(1, 6).sum() == 15 && iter.range(1, 5).product() == 24 {
    return 0;
  }
  return 1;
}
