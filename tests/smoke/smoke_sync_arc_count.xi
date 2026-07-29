module smoke_sync_arc_count
use xiom.sync;

fn main() -> Int {
  var a = sync.Arc.new(1);
  if a.strong_count() != 1 { return 1; }

  var b = a.clone();
  if a.strong_count() != 2 { return 2; }

  var c = a.clone();
  if a.strong_count() != 3 { return 3; }
  if b.strong_count() != 3 { return 4; }
  if c.strong_count() != 3 { return 5; }

  return 0;
}
