// XIOM stdlib stress -- xiom.string.replace multiple occurrences
// Tests replacing all occurrences of a pattern in a repeated string.
// Returns 0 on success, nonzero on failure.

module smoke_stress_string_replace_multi
use xiom.string;

fn main() -> Int {
  var s = "a.a.a.a";
  var r = xiom.string.replace(s, ".", "/");
  if r == "a/a/a/a" { return 0; } else { return 1; }
}
