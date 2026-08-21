// XIOM stdlib stress -- xiom.string.char_at out-of-bounds
// Tests char_at returns None for indices past the end of the string.
// Returns 0 on success, nonzero on failure.

module smoke_stress_string_char_at_oob
use xiom.string;

fn main() -> Int {
  var s = "AB";
  match xiom.string.char_at(s, 0) {
    Some(c) => { if c != 'A' { return 1; } }
    None => { return 2; }
  }
  match xiom.string.char_at(s, 1) {
    Some(c) => { if c != 'B' { return 3; } }
    None => { return 4; }
  }
  match xiom.string.char_at(s, 2) {
    Some(_) => { return 5; }
    None => { }
  }
  match xiom.string.char_at(s, 999) {
    Some(_) => { return 6; }
    None => { }
  }
  return 0;
}
