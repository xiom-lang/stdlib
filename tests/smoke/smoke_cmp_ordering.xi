module smoke_cmp_ordering
use xiom.cmp;

fn main() -> Int {
  if cmp.Less != cmp.Less { return 0; }
  if cmp.Equal != cmp.Equal { return 0; }

  if cmp.Ordering.Less.reverse() != cmp.Greater { return 1; }
  if cmp.Ordering.Greater.reverse() != cmp.Less { return 2; }
  if cmp.Ordering.Equal.reverse() != cmp.Equal { return 3; }

  if cmp.Ordering.Equal.then(cmp.Less) != cmp.Less { return 4; }
  if cmp.Ordering.Less.then(cmp.Greater) != cmp.Less { return 5; }

  return 0;
}
