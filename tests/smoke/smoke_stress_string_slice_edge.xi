// XIOM stdlib stress — xiom.string.str_slice edge positions
// Slices at start=0, start==end, and end==len; verifies each case.
// Returns 0 on success.

module smoke_stress_string_slice_edge
use xiom.string;

fn main() -> Int {
  var s = "abcdef";
  var n = xiom.string.str_len(s);
  var full = xiom.string.str_slice(s, 0, n);
  var empty = xiom.string.str_slice(s, 3, 3);
  var tail = xiom.string.str_slice(s, n, n);
  if full == "abcdef" && empty == "" && tail == "" { return 0; } else { return 1; }
}
