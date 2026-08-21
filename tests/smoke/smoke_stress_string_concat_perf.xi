// XIOM stdlib stress -- xiom.string.str_concat repeated growth performance
// Chains several concatenations to stress allocator, verifies result.
// Returns 0 on success.

module smoke_stress_string_concat_perf
use xiom.string;

fn main() -> Int {
  var r = "a";
  r = xiom.string.str_concat(r, "b");
  r = xiom.string.str_concat(r, "c");
  r = xiom.string.str_concat(r, "d");
  r = xiom.string.str_concat(r, "e");
  r = xiom.string.str_concat(r, r);
  if r == "abcdeabcde" { return 0; } else { return 1; }
}
