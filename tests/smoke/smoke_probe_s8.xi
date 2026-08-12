module smoke_probe_s8
use xiom.search.binary;
use xiom.search.linear;
use xiom.search.interpolation;
use xiom.io;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(1); v.push(3); v.push(5);
  var r = binary_search(&v, 5);
  match r {
    Some(i) => { if i != 2 { return 1; } },
    None => { return 2; },
  }
  io.println("OK");
  return 0;
}

