module smoke_iter_collect
use xiom.iter;
use xiom.collections;

fn main() -> Int {
  var r = iter.range(1, 6);
  var items = r.collect();
  if items.len() != 5 { return 1; }
  var i: Int = 0;
  while i < 5 {
    match items.get(i) {
      Some(v) => { if v != i + 1 { return 2; } },
      None => { return 3; },
    };
    i = i + 1;
  }

  var empty = iter.range(0, 0).collect();
  if empty.len() != 0 { return 4; }

  return 0;
}
