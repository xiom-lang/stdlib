module smoke_cmp_chains
use xiom.cmp;

fn main() -> Int {
  var result = cmp.Ordering.Equal
    .then(cmp.Less)
    .then(cmp.Greater);
  if result != cmp.Less { return 1; }

  var r2 = cmp.Ordering.Less.then_with(fn() -> cmp.Ordering { return cmp.Greater; });
  if r2 != cmp.Less { return 2; }

  var r3 = cmp.Ordering.Equal.then_with(fn() -> cmp.Ordering { return cmp.Greater; });
  if r3 != cmp.Greater { return 3; }

  return 0;
}
