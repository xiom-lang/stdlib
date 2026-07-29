// XIOM stdlib smoke test — xiom.async (production-grade)
// Tests: Executor.new, sleep_ms, Channel unbounded send/try_recv
// Returns 0 on success, unique error code on failure.

module smoke_async
use xiom.async;

fn main() -> Int {
  // 1. Create Executor
  var exec = Executor.new();

  // 2. sleep_ms completes
  sleep_ms(1);

  // 3. Channel unbounded: send then try_recv
  var ch = Channel.unbounded();
  ch.send(42);
  var val = ch.try_recv();
  match val {
    Some(v) => { if v != 42 { return 3; } }
    None => { return 3; }
  }

  // 4. Channel try_recv on empty returns None
  var ech = Channel.unbounded();
  var ev = ech.try_recv();
  match ev {
    Some(_) => { return 4; }
    None => {}
  }

  return 0;
}
