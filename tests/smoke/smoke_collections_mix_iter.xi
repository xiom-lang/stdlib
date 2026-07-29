module smoke_collections_mix_iter
use xiom.collections;
use xiom.iter;

fn main() -> Int {
  var v = Vec[Int].new();
  var r = iter.range(1, 11);
  var items = r.collect();
  var i: Int = 0;
  while i < items.len() {
    v.push(items.get(i).unwrap_or(0));
    i = i + 1;
  }
  if v.len() != 10 { return 1; }

  var total: Int = 0;
  var j: Int = 0;
  while j < v.len() {
    match v.get(j) {
      Some(x) => { total = total + x; },
      None => {},
    };
    j = j + 1;
  }
  if total != 55 { return 2; }

  return 0;
}
