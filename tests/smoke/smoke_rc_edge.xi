module smoke_rc_edge
use xiom.rc;

fn main() -> Int {
  var r = rc.Rc.new(0);
  if r.get() != 0 { return 1; }
  if r.strong_count() != 1 { return 2; }

  var w = r.downgrade();
  var w2 = r.downgrade();
  if r.weak_count() != 2 { return 3; }

  match w.upgrade() {
    Some(up) => { if up.get() != 0 { return 4; } },
    None => { return 5; },
  };
  match w2.upgrade() {
    Some(up) => { if up.get() != 0 { return 6; } },
    None => { return 7; },
  };

  return 0;
}
