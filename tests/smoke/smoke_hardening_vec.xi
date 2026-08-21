// XIOM -- Vec[UInt8] elem_size hardening test
// Verifies that narrow-type Vec stores elements at correct byte width.
// Vec[UInt8] -> 1 byte per element (not 8).
// Returns 0 on success, nonzero on failure:
//   1 = len mismatch, 2-5 = value mismatch at index

module test_hardening_vec_u8_elem_size

fn main() -> Int {
  // Test 1: Push and read back 3 bytes
  var v = Vec[UInt8].new();
  v.push(97);   // 'a'
  v.push(98);   // 'b'
  v.push(99);   // 'c'
  if v.len() != 3 { return 1; }
  if v[0] != 97 { return 2; }
  if v[1] != 98 { return 3; }
  if v[2] != 99 { return 4; }

  // Test 2: Push 32 elements (triggers Vec growth with elem_size)
  var v2 = Vec[UInt8].new();
  var i = 0;
  while i < 32 {
    v2.push(i as UInt8);
    i = i + 1;
  }
  if v2.len() != 32 { return 1; }
  i = 0;
  while i < 32 {
    if v2[i] != i as UInt8 { return 5; }
    i = i + 1;
  }

  // Test 3: Vec[Int] still works with elem_size=8
  var v3 = Vec[Int].new();
  v3.push(0xDEADBEEF);
  v3.push(0xCAFEBABE);
  if v3.len() != 2 { return 1; }
  if v3[0] != 0xDEADBEEF { return 6; }
  if v3[1] != 0xCAFEBABE { return 7; }

  return 0;
}
