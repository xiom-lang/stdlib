// p_wave4_shapes.xi -- wave-4 contract shape pre-validation.
// Exercises the new char.xi clauses (Option-implies, radix guards, utf8
// length bounds) on valid + invalid inputs; any clause that is wrong aborts.
module p_wave4_shapes
use xiom.char;
use xiom.string.combinatorics;
use xiom.io;

fn first(s: Str) -> Char {
  match s.char_at(0) {
    Some(c) => { return c; },
    None => { return 'x'; }
  }
}

fn main() -> Int {
  if char.len_utf8('A') != 1 { return 1; };
  if char.len_utf8(first("\u{00E9}")) != 2 { return 2; };
  if char.len_utf8(first("\u{4E2D}")) != 3 { return 3; };
  if char.len_utf8(first("\u{1F600}")) != 4 { return 4; };

  match char.to_digit('7', 10) {
    Some(v) => { if v != 7 { return 5; }; },
    None => { return 6; }
  };
  match char.to_digit('7', 1) {
    Some(_) => { return 7; },
    None => { }
  };
  match char.to_digit('f', 16) {
    Some(v) => { if v != 15 { return 8; }; },
    None => { return 9; }
  };

  match char.from_digit(10, 16) {
    Some(c) => { if c != 'A' { return 10; }; },
    None => { return 11; }
  };
  match char.from_digit(99, 16) {
    Some(_) => { return 12; },
    None => { }
  };
  match char.from_digit(5, 1) {
    Some(_) => { return 13; },
    None => { }
  };

  // rotate family: length-preserving ensures
  if combinatorics.str_rotate_left("abcde", 2) != "cdeab" { return 14; };
  if combinatorics.str_rotate_right("abcde", 2) != "deabc" { return 15; };
  if combinatorics.str_rotate("abcde", 2) != "deabc" { return 16; };
  if combinatorics.str_rotate("", 5) != "" { return 17; };
  if combinatorics.str_rotate("abc", 0) != "abc" { return 18; };

  io.println("P_WAVE4_SHAPES OK");
  io.flush_stdout();
  0
}
