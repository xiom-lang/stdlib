module smoke_sync_arc_atomic_mix
use xiom.sync;

fn main() -> Int {
  var ai = sync.AtomicInt.new(0);
  ai.store(100);
  if ai.load() != 100 { return 1; }

  ai.fetch_add(50);
  if ai.load() != 150 { return 2; }

  var a = sync.Arc.new(99);
  var b = a.clone();
  if a.get() != 99 { return 3; }
  if a.strong_count() != 2 { return 4; }

  return 0;
}
