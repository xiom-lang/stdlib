module p_ct_tower
use xiom.convert.from;
use xiom.convert.into;
use xiom.io;

fn main() -> Int {
  var fi = from.from_int(42);
  if fi != 42.0 { io.println("from_int"); return 1; }
  var ifl = into.into_float(7);
  if ifl != 7.0 { io.println("into_float"); return 2; }
  io.println("CT TOWER OK");
  return 0;
}
