module smoke_probe_iter10
use xiom.iter.map;
use xiom.io;

fn double(x: &Int) -> Int {
  *x * 2
}

fn main() -> Int {
  var r = Vec[Int].new();
  r.push(1); r.push(2); r.push(3); r.push(4);
  var m = iter_map(&r, double);
  if !(m[0] == 2 && m[1] == 4 && m[2] == 6 && m[3] == 8) { io.println("m:bad"); return 3; }
  io.println("OK");
  return 0;
}
