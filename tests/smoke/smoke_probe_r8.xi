module smoke_probe_r8
use xiom.iter.fold;
use xiom.iter.range;
use xiom.io;
fn main() -> Int {
  var r = xiom.iter.range.range(1, 5);
  if r.len() != 4 { io.println("r8:len"); return 1; }
  if r[0] != 1 || r[3] != 4 { io.println("r8:val"); return 2; }
  io.println("OK");
  return 0;
}
