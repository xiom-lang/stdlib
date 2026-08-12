module smoke_probe_r1
use xiom.iter.range;
use xiom.io;
fn main() -> Int {
  var r = range(1, 5);
  if r.len() != 4 { io.println("r1:len"); return 1; }
  if r[0] != 1 || r[3] != 4 { io.println("r1:val"); return 2; }
  io.println("OK");
  return 0;
}
