module smoke_cmp_derived
use xiom.cmp;

fn main() -> Int {
  if cmp.max(1, 2) != cmp.max_int(1, 2) { return 1; }
  if cmp.min(1, 2) != cmp.min_int(1, 2) { return 2; }

  return 0;
}
