module smoke_iter_pipeline
use xiom.iter;

fn main() -> Int {
  var result = iter.range(1, 50)
    .filter(fn(x: &Int) -> Bool { return *x % 3 == 0; })
    .map(fn(x: Int) -> Int { return x * x; })
    .filter(fn(x: &Int) -> Bool { return *x < 2000; })
    .take(5)
    .collect();

  if result.len() != 5 { return 1; }
  match result.get(0) { Some(v) => { if v != 9 { return 2; } }, None => { return 3; }, };
  match result.get(4) { Some(v) => { if v != 729 { return 4; } }, None => { return 5; }, };

  return 0;
}
