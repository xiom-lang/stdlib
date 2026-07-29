module smoke_sync_arc_get
use xiom.sync;

fn main() -> Int {
  var a = sync.Arc.new("hello");
  if a.get() != "hello" { return 1; }

  var a2 = sync.Arc.new(42);
  if a2.get() != 42 { return 2; }

  var a3 = sync.Arc.new(true);
  if !a3.get() { return 3; }

  return 0;
}
