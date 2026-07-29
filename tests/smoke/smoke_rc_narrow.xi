module smoke_rc_narrow
use xiom.rc;

fn main() -> Int {
  var r8 = rc.Rc.new(100 as Int8);
  if r8.get() != 100 as Int8 { return 1; }

  var r16 = rc.Rc.new(30000 as Int16);
  var r16c = r16.clone();
  if r16c.get() != 30000 as Int16 { return 2; }

  var r32 = rc.Rc.new(1000000 as Int32);
  if r32.strong_count() != 1 { return 3; }

  return 0;
}
