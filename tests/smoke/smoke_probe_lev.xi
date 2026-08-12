module smoke_probe_lev
use xiom.misc.levenshtein;
use xiom.convert;
use xiom.io;

fn main() -> Int {
  var a = levenshtein_distance_limited("kitten", "sitting", 5);
  io.println("lim5=");
  io.println(convert.int_to_string(a));
  if a != 3 { return 1; }
  var b = levenshtein_distance_limited("kitten", "sitting", 2);
  if b != 3 { return 2; }
  io.println("OK");
  return 0;
}
