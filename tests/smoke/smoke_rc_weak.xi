module smoke_rc_weak
use xiom.rc;

fn main() -> Int {
  var r = rc.Rc.new(100);

  var w = r.downgrade();
  if r.weak_count() != 1 { return 1; }

  match w.upgrade() {
    Some(up) => {
      if up.get() != 100 { return 2; }
      if up.strong_count() != 2 { return 3; }
      up.drop();
    },
    None => { return 4; },
  };

  if r.strong_count() != 1 { return 5; }
  if r.weak_count() != 1 { return 6; }

  return 0;
}
