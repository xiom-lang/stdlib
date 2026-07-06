// NOTE: link/run smoke only
// XIOM stdlib smoke test — xiom.rand
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_rand
use xiom.rand;

fn main() -> Int {
  let r = rand.random();
  if r >= 0.0 && r < 1.0 {
    return 0;
  }
  return 1;
}
