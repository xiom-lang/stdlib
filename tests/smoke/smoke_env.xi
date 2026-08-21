// NOTE: link/run smoke only
// XIOM stdlib smoke test -- xiom.env
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_env
use xiom.env;

fn main() -> Int {
  if env.OS != "" {
    return 0;
  }
  return 1;
}
