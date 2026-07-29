module smoke_core_option_basic
use xiom.core;

fn main() -> Int {
  let s = Some(42);
  match s {
    Some(v) => { if v != 42 { return 1; } },
    None => { return 2; },
  };
  if !s.is_some { return 3; }

  let n: Option[Int] = None;
  match n {
    Some(_) => { return 4; },
    None => {},
  };
  if n.is_some { return 5; }

  return 0;
}
