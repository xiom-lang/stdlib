module smoke_cmp_by
use xiom.cmp;

fn main() -> Int {
  var result = cmp.min_by(10, 20, fn(a: &Int, b: &Int) -> cmp.Ordering {
    if *a < *b { return cmp.Less; };
    if *a > *b { return cmp.Greater; };
    return cmp.Equal;
  });
  if result != 10 { return 1; }

  var result2 = cmp.max_by(10, 20, fn(a: &Int, b: &Int) -> cmp.Ordering {
    if *a < *b { return cmp.Less; };
    if *a > *b { return cmp.Greater; };
    return cmp.Equal;
  });
  if result2 != 20 { return 2; }

  return 0;
}
