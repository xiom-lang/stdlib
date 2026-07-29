module smoke_cmp_then
use xiom.cmp;

fn main() -> Int {
  var result = cmp.Ordering.Equal.then(cmp.Less);
  if result != cmp.Less { return 1; }

  var result2 = cmp.Ordering.Greater.then(cmp.Less);
  if result2 != cmp.Greater { return 2; }

  return 0;
}
