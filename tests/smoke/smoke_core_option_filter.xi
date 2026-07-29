module smoke_core_option_filter
use xiom.core;

fn main() -> Int {
  let s = Some(42);
  let filtered = s.filter(fn(x: &Int) -> Bool { return *x > 40; });
  match filtered {
    Some(v) => { if v != 42 { return 1; } },
    None => { return 2; },
  };

  let filtered2 = s.filter(fn(x: &Int) -> Bool { return *x > 100; });
  if filtered2.is_some { return 3; }

  let n: Option[Int] = None;
  let filtered_none = n.filter(fn(x: &Int) -> Bool { return true; });
  if filtered_none.is_some { return 4; }

  if !s.is_some_and(fn(x: &Int) -> Bool { return *x == 42; }) { return 5; }
  if s.is_some_and(fn(x: &Int) -> Bool { return *x != 42; }) { return 6; }
  if n.is_some_and(fn(x: &Int) -> Bool { return true; }) { return 7; }

  return 0;
}
