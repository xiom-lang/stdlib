// XIOM stdlib smoke test — xiom.async (production-grade)
// Tests: Executor.new, sleep_ms, Channel unbounded send/try_recv
// Returns 0 on success, unique error code on failure.

module smoke_async
use xiom.async;

fn main() -> Int {
  // 1. Create Executor
  let exec = Executor.new();

  // 2. sleep_ms completes
  sleep_ms(1);

  // 3. Channel unbounded: send then try_recv
  let ch = Channel.unbounded();
  ch.send(42);
  let val = ch.try_recv();
  match val {
    Some(v) => { if v != 42 { return 3; } }
    None => { return 3; }
  }

  // 4. Channel try_recv on empty returns None
  let ech = Channel.unbounded();
  let ev = ech.try_recv();
  match ev {
    Some(_) => { return 4; }
    None => {}
  }

  return 0;
}
