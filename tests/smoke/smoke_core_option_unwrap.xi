module smoke_core_option_unwrap
use xiom.core;

fn main() -> Int {
  let s = Some(42);
  if s.unwrap_or(0) != 42 { return 1; }

  let n: Option[Int] = None;
  if n.unwrap_or(99) != 99 { return 2; }

  if s.unwrap_or_else(fn() -> Int { return 0; }) != 42 { return 3; }
  if n.unwrap_or_else(fn() -> Int { return 7; }) != 7 { return 4; }

  if s.and_then(fn(x: Int) -> Option[Int] { return Some(x * 2); }).unwrap_or(0) != 84 { return 5; }
  let n2: Option[Int] = None;
  if n2.and_then(fn(x: Int) -> Option[Int] { return Some(x * 2); }).is_some { return 6; }

  return 0;
}
