// XIOM stdlib smoke test — xiom.async
// Spawns a task onto the global executor, drives it with run(), and asserts
// the task actually ran (proving the real ready-queue executor works).
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_async
use xiom.async;

var async_ran: Int = 0;

fn async_task() {
  async_ran = async_ran + 1;
}

fn main() -> Int {
  async_ran = 0;
  spawn(async_task);
  run();
  if async_ran == 1 {
    return 0;
  }
  return 1;
}
