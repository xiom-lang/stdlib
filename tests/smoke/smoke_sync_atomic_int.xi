module smoke_sync_atomic_int
use xiom.sync;

fn main() -> Int {
  var ai = sync.AtomicInt.new(0);
  if ai.load() != 0 { return 1; }

  ai.store(42);
  if ai.load() != 42 { return 2; }

  var old = ai.fetch_add(10);
  if old != 42 { return 3; }
  if ai.load() != 52 { return 4; }

  var old2 = ai.fetch_sub(2);
  if old2 != 52 { return 5; }
  if ai.load() != 50 { return 6; }

  return 0;
}
