// XIOM stdlib stress -- xiom.string.lines / words splitting
// Splits multi-line text and spaced text, verifies counts.
// Returns 0 on success.

module smoke_stress_string_lines_words
use xiom.string;

fn main() -> Int {
  var s = "a\nb\nc";
  var lns = xiom.string.lines(s);
  var w = xiom.string.words("one two three");
  if lns.len() == 3 && w.len() == 3 { return 0; } else { return 1; }
}
