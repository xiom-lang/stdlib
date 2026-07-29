module smoke_core_option_deep_chain
use xiom.core;

fn div2(x: Int) -> Option[Int] {
  if x % 2 == 0 { return Some(x / 2); }
  return None;
}

fn add1(x: Int) -> Option[Int] {
  return Some(x + 1);
}

fn main() -> Int {
  var o = Some(10);
  var result = o
    .and_then(div2)
    .and_then(add1)
    .and_then(div2)
    .map(fn(x: Int) -> Int { return x * 3; });
  match result {
    Some(v) => { if v != 9 { return 1; } },
    None => { return 2; },
  };

  var o2 = Some(3);
  var result2 = o2.and_then(div2);
  match result2 {
    Some(_) => { return 3; },
    None => {},
  };

  return 0;
}
