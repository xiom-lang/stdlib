// XIOM stdlib smoke test — xiom.async (production-grade)
module smoke_async
use xiom.async;

fn main() -> Int {
  // 1. Create Executor
  let exec = Executor.new();

  // 2. sleep_ms completes
  sleep_ms(1);

  return 0;
}
