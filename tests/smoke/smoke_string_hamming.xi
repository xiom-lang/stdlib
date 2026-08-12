// Smoke test for xiom.string.hamming
// Returns 0 on success, non-zero on the first failing assertion.

module smoke_string_hamming
use xiom.string.hamming;
use xiom.io;

fn main() -> Int {
  if hamming.hamming_distance("karolin", "kathrin") != 3 { io.println("hamming karolin"); return 1; }
  if hamming.hamming_distance("abc", "abd") != 1 { io.println("hamming sub"); return 2; }
  if hamming.hamming_distance("abc", "xyz") != 3 { io.println("hamming diff"); return 3; }
  if hamming.hamming_distance("", "") != 0 { io.println("hamming empty"); return 4; }
  if hamming.hamming_distance("abc", "abc") != 0 { io.println("hamming equal"); return 5; }
  if hamming.hamming_distance("kitten", "sitting") != -1 { io.println("hamming len"); return 6; }
  if hamming.hamming_distance("abc", "ab") != -1 { io.println("hamming len2"); return 7; }
  io.println("smoke_string_hamming: OK");
  return 0;
}
