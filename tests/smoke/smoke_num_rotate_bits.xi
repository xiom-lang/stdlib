module smoke_num_rotate_bits
use xiom.num;

fn main() -> Int {
  if num.rotate_left(1, 1) != 2 { return 1; }
  if num.rotate_left(1, 0) != 1 { return 2; }
  if num.rotate_left(0, 10) != 0 { return 3; }
  if num.rotate_left(1, 64) != 1 { return 4; }

  if num.rotate_right(2, 1) != 1 { return 5; }
  if num.rotate_right(1, 0) != 1 { return 6; }

  var original = 0x12345678;
  var rotated = num.rotate_left(original, 16);
  var restored = num.rotate_right(rotated, 16);
  if restored != original { return 7; }

  if num.reverse_bits(1) != -9223372036854775808 { return 8; }
  if num.reverse_bits(0) != 0 { return 9; }

  return 0;
}
