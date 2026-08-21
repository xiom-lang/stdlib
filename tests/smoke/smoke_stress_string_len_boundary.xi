// XIOM stdlib stress -- xiom.string.str_len on boundary strings
// Tests length of empty string and single-character string.
// Returns 0 on success.

module smoke_stress_string_len_boundary
use xiom.string;

fn main() -> Int {
  if xiom.string.str_len("") == 0 && xiom.string.str_len("x") == 1 {
    return 0;
  }
  return 1;
}
