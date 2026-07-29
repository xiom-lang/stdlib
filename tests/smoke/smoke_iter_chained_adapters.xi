module smoke_iter_chained_adapters
use xiom.iter;

fn main() -> Int {
  var result = iter.range(1, 20)
    .filter(fn(x: &Int) -> Bool { return *x % 2 == 0; })
    .map(fn(x: Int) -> Int { return x * 10; })
    .take(5)
    .collect();

  if result.len() != 5 { return 1; }
  match result.get(0) {
    Some(v) => { if v != 20 { return 2; } },
    None => { return 3; },
  };
  match result.get(4) {
    Some(v) => { if v != 100 { return 4; } },
    None => { return 5; },
  };

  return 0;
}
