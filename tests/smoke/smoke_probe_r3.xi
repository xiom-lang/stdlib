module smoke_probe_r3
use xiom.iter.range;
use xiom.io;
fn main() -> Int {
  var r = range_count(5);
  if r.len() != 5 { io.println("r3:len"); return 1; }
  if r[0] != 0 || r[4] != 4 { io.println("r3:val"); return 2; }
  var c = range_char('a', 'c');
  if c.len() != 2 { io.println("r3:clen"); return 3; }
  io.println("OK");
  return 0;
}
