module smoke_probe_iter8
use xiom.iter.map;
use xiom.io;

fn main() -> Int {
  var r = Vec[Int].new();
  r.push(1); r.push(2);
  if r.len() != 2 { io.println("i8:len"); return 1; }
  io.println("OK");
  return 0;
}
