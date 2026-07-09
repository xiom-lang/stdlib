// XIOM stdlib smoke test — xiom.async
// Link/run smoke: spawns a no-op task onto the global executor and drives it
// with run(), proving the executor links and runs without crashing.
// (Module-global mutation to observe the task is a separate checker feature.)
// Returns 0 on success.

module smoke_async
use xiom.async;

fn async_task() {
  // no-op task body
  let _ = 1 + 1;
}

fn main() -> Int {
  spawn(async_task);
  run();
  return 0;
}
