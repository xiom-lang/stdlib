module smoke_core_slice
use xiom.core;

fn main() -> Int {
  let a = [1, 2, 3, 4, 5];
  if !core.is_sorted(a) { return 1; }
  if !core.contains(a, 3) { return 2; }
  if core.contains(a, 99) { return 3; }

  if !core.all(a, fn(x: Int) -> Bool { return x > 0; }) { return 4; }
  if core.all(a, fn(x: Int) -> Bool { return x > 3; }) { return 5; }

  if !core.none(a, fn(x: Int) -> Bool { return x > 100; }) { return 6; }
  if core.none(a, fn(x: Int) -> Bool { return x > 0; }) { return 7; }

  return 0;
}
