module smoke_sync_arc_new
use xiom.sync;

fn main() -> Int {
  var a = sync.Arc.new(42);
  if a.strong_count() != 1 { return 1; }

  var val = a.get();
  if val != 42 { return 2; }

  return 0;
}
