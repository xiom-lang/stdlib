module smoke_probe_iter9
use xiom.iter.filter;
use xiom.io;

fn is_even(x: &Int) -> Bool {
  *x % 2 == 0
}

fn main() -> Int {
  var r = Vec[Int].new();
  r.push(1); r.push(2); r.push(3); r.push(4);
  var c = xiom.iter.filter.iter_count_if(&r, is_even);
  if c != 2 { io.println("i9:cnt"); return 1; }
  io.println("OK");
  return 0;
}
