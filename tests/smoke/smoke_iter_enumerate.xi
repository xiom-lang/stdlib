module smoke_iter_enumerate
use xiom.iter;

fn main() -> Int {
  var items = iter.range(10, 13).enumerate().collect();
  if items.len() != 3 { return 1; }
  match items.get(0) {
    Some((i, v)) => { if i != 0 { return 2; }; if v != 10 { return 3; }; },
    None => { return 4; },
  };
  match items.get(2) {
    Some((i, v)) => { if i != 2 { return 5; }; if v != 12 { return 6; }; },
    None => { return 7; },
  };

  return 0;
}
