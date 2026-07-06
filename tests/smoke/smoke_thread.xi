// NOTE: link/run smoke only
// XIOM stdlib smoke test — xiom.thread
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_thread
use xiom.thread;

fn main() -> Int {
  let n = thread.available_parallelism();
  if n > 0 {
    return 0;
  }
  return 1;
}
