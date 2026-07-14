// XIOM stdlib smoke test — xiom.thread (production-grade)
module smoke_thread
use xiom.thread;

fn main() -> Int {
  // 1. available_parallelism returns positive value
  let ap = available_parallelism();
  if ap <= 0 { return 1; }

  // 2. hardware_threads matches available_parallelism
  let ht = hardware_threads();
  if ht != ap { return 2; }

  // 3. sleep_ms completes without error
  sleep_ms(1);

  // 4. yield_now completes without error
  yield_now();

  // 5. current_thread_id returns positive value
  let tid = current_thread_id();
  if tid <= 0 { return 5; }

  // 6. Thread.current returns valid thread with positive id
  let t = Thread.current();
  if t.id() <= 0 { return 6; }

  return 0;
}
