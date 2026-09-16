module p_lev_shim_first
use xiom.io;
use xiom.convert;
fn main() -> Int {
  var d = xiom.string.levenshtein.levenshtein_distance("kitten", "sitting");
  io.println("lev=" + convert.int_to_string(d));
  return 0;
}
