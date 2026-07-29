module smoke_cmp_partial
use xiom.cmp;

fn main() -> Int {
  var rev = cmp.Ordering.Less.reverse();
  if rev != cmp.Greater { return 1; }

  var rev2 = cmp.Ordering.Greater.reverse();
  if rev2 != cmp.Less { return 2; }

  var rev3 = cmp.Ordering.Equal.reverse();
  if rev3 != cmp.Equal { return 3; }

  return 0;
}
