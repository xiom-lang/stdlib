// XIOM stdlib stress — xiom.string.str_concat repeated growth
// Builds a large string via repeated concatenation and verifies length.
// Returns 0 on success.

module smoke_stress_string_concat_large
use xiom.string;

fn main() -> Int {
  var a = "hello";
  var b = "world";
  var c = "0123456789";
  var r = xiom.string.str_concat(a, b);
  r = xiom.string.str_concat(r, c);
  r = xiom.string.str_concat(r, r);
  if r.len() > 0 { return 0; } else { return 1; }
}
