module smoke_cross_collections_iter_fold
use xiom.collections;
use xiom.iter;

fn main() -> Int {
  var v = Vec[Int].new();
  var r = iter.range(1, 21);
  var items = r.collect();

  var i: Int = 0;
  while i < items.len() {
    match items.get(i) {
      Some(x) => { v.push(x); },
      None => {},
    };
    i = i + 1;
  }

  var total = iter.range(0, v.len()).fold(0, fn(acc: Int, idx: Int) -> Int {
    match v.get(idx) {
      Some(x) => { return acc + x; },
      None => { return acc; },
    };
  });

  if total != 210 { return 1; }

  return 0;
}
