module smoke_rc_basic
use xiom.rc;

fn main() -> Int {
  var r = rc.Rc.new(42);
  if r.strong_count() != 1 { return 1; }
  if r.get() != 42 { return 2; }

  var r2 = r.clone();
  if r.strong_count() != 2 { return 3; }
  if r2.strong_count() != 2 { return 4; }

  if r.get() != 42 { return 5; }
  if r2.get() != 42 { return 6; }

  if !r.ptr_eq(&r2) { return 7; }

  var r3 = rc.Rc.new(42);
  if r.ptr_eq(&r3) { return 8; }

  return 0;
}
