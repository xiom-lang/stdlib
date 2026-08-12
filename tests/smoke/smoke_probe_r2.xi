module smoke_probe_r2
use xiom.io;
fn main() -> Int {
  var r = xiom.iter.range.range(1, 5);
  if r.len() != 4 { io.println("r2:len"); return 1; }
  if r[0] != 1 || r[3] != 4 { io.println("r2:val"); return 2; }
  io.println("OK");
  return 0;
}
