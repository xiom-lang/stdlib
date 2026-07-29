module smoke_sync_edge
use xiom.sync;

fn main() -> Int {
  var ai = sync.AtomicInt.new(0);
  ai.store(0);
  if ai.load() != 0 { return 1; }

  var ab = sync.AtomicBool.new(false);
  ab.store(false);
  if ab.load() { return 2; }

  var a = sync.Arc.new(0);
  if a.strong_count() != 1 { return 3; }

  return 0;
}
