// XIOM stdlib stress -- xiom.string.lines on empty string
// Tests lines() returns correct count for empty and blank input.
// Returns 0 on success, nonzero on failure.

module smoke_stress_string_lines_empty
use xiom.string;

fn main() -> Int {
  var l1 = xiom.string.lines("");
  if l1.len() != 1 { return 1; }
  var l2 = xiom.string.lines("\n");
  if l2.len() != 2 { return 2; }
  var l3 = xiom.string.lines("a\nb\nc");
  if l3.len() != 3 { return 3; }
  return 0;
}
