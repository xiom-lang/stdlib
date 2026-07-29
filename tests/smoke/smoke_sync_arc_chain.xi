module smoke_sync_arc_chain
use xiom.sync;

fn main() -> Int {
  var a = sync.Arc.new(10);
  var b = a.clone();
  var c = b.clone();
  var d = c.clone();

  if a.strong_count() != 4 { return 1; }
  if a.get() != 10 { return 2; }
  if d.get() != 10 { return 3; }

  if !a.ptr_eq(&d) { return 4; }
  if !b.ptr_eq(&c) { return 5; }

  var e = sync.Arc.new(10);
  if a.ptr_eq(&e) { return 6; }

  return 0;
}
