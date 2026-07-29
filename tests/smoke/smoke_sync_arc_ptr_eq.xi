module smoke_sync_arc_ptr_eq
use xiom.sync;

fn main() -> Int {
  var a = sync.Arc.new(42);
  var b = a.clone();
  var c = sync.Arc.new(42);

  if !a.ptr_eq(&b) { return 1; }
  if a.ptr_eq(&c) { return 2; }

  return 0;
}
