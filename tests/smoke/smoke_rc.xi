// XIOM stdlib smoke test — xiom.rc
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_rc
use xiom.rc;

fn main() -> Int {
  let r = rc.Rc.new(42);
  let r2 = r.clone();
  if r.get() == 42 && r2.get() == 42 && r.strong_count() == 2 {
    return 0;
  }
  return 1;
}
