// XIOM stdlib stress — xiom.string.words with multiple spaces
// Tests words() handles consecutive whitespace and trims boundaries.
// Returns 0 on success, nonzero on failure.

module smoke_stress_string_words_multi
use xiom.string;

fn main() -> Int {
  var w1 = xiom.string.words("  one   two  three  ");
  if w1.len() != 3 { return 1; }
  if w1[0] != "one" { return 2; }
  if w1[1] != "two" { return 3; }
  if w1[2] != "three" { return 4; }
  var w2 = xiom.string.words("");
  if w2.len() != 0 { return 5; }
  var w3 = xiom.string.words("   ");
  if w3.len() != 0 { return 6; }
  return 0;
}
