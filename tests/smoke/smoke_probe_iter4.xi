module smoke_probe_iter4
use xiom.iter.chain;
use xiom.iter.filter;
use xiom.iter.fold;
use xiom.iter.map;
use xiom.iter.range;
use xiom.io;

fn double(x: &Int) -> Int {
  *x * 2
}

fn main() -> Int {
  var r = xiom.iter.range.range(1, 5);
  if r.len() != 4 { io.println("r:len"); return 1; }
  var m = xiom.iter.map.iter_map(&r, double);
  if !(m[0] == 2 && m[1] == 4 && m[2] == 6 && m[3] == 8) { io.println("m:bad"); return 3; }
  io.println("OK");
  return 0;
}
