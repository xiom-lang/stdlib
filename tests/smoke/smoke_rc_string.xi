module smoke_rc_string
use xiom.rc;

fn main() -> Int {
  var r = rc.Rc.new("hello");
  if r.get() != "hello" { return 1; }

  var r2 = r.clone();
  if r.strong_count() != 2 { return 2; }
  if r2.get() != "hello" { return 3; }

  return 0;
}
