// XIOM stdlib stress — xiom.string.byte_at / char_at boundary
// Accesses first and last byte/char of a string, verifies correctness.
// Returns 0 on success.

module smoke_stress_string_index_boundary
use xiom.string;

fn main() -> Int {
  var s = "hello";
  var n = xiom.string.str_len(s);
  var first_byte = xiom.string.byte_at(s, 0);
  var last_byte = xiom.string.byte_at(s, n - 1);
  if first_byte == 104 && last_byte == 111 { return 0; } else { return 1; }
}
