module smoke_iter_filter
use xiom.iter;

fn main() -> Int {
  var r = iter.range(1, 11);
  var evens = r.filter(fn(x: &Int) -> Bool { return *x % 2 == 0; }).collect();
  if evens.len() != 5 { return 1; }
  match evens.get(0) { Some(v) => { if v != 2 { return 2; } }, None => { return 3; }, };
  match evens.get(4) { Some(v) => { if v != 10 { return 4; } }, None => { return 5; }, };

  return 0;
}
