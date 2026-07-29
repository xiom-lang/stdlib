module smoke_iter_narrow
use xiom.iter;

fn main() -> Int {
  var r = iter.range(0 as Int8, 10 as Int8);
  if r.sum() != 45 { return 1; }

  var items = iter.range(1 as Int16, 6 as Int16).collect();
  if items.len() != 5 { return 2; }

  var total: Int32 = iter.range(1, 101).sum() as Int32;
  if total != 5050 as Int32 { return 3; }

  return 0;
}
