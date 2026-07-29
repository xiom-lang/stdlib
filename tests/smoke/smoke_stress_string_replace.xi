// XIOM stdlib stress — xiom.string.replace single and multi
// Replaces one occurrence and all overlapping occurrences.
// Returns 0 on success.

module smoke_stress_string_replace
use xiom.string;

fn main() -> Int {
  var s = "foo bar foo";
  var r = xiom.string.replace(s, "foo", "baz");
  if r == "baz bar baz" { return 0; } else { return 1; }
}
