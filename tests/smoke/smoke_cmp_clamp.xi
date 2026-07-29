module smoke_cmp_clamp
use xiom.cmp;

fn main() -> Int {
  if cmp.clamp(5, 0, 10) != 5 { return 1; }
  if cmp.clamp(-1, 0, 10) != 0 { return 2; }
  if cmp.clamp(15, 0, 10) != 10 { return 3; }
  if cmp.clamp(0, 0, 0) != 0 { return 4; }
  if cmp.clamp(5, 5, 5) != 5 { return 5; }

  return 0;
}
