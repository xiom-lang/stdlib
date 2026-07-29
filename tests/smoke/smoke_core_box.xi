module smoke_core_box
use xiom.core;

fn main() -> Int {
  let b = Box[Int].new(42);
  let val = b.get();
  if *val != 42 { return 1; }

  let b2 = Box[Int].new(99);
  let val2 = b2.get();
  if *val2 != 99 { return 2; }

  return 0;
}
