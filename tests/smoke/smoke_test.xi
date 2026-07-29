module smoke_test
use xiom.test;

fn main() -> Int {
  var r = test.assert(true, "t");
  return 0;
}
