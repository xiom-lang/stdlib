module smoke_num_leading_trailing_zeros
use xiom.num;

fn main() -> Int {
  if num.leading_zeros(1) != 63 { return 1; }
  if num.leading_zeros(4) != 61 { return 2; }
  if num.leading_zeros(0) != 64 { return 3; }

  if num.trailing_zeros(1) != 0 { return 4; }
  if num.trailing_zeros(4) != 2 { return 5; }
  if num.trailing_zeros(8) != 3 { return 6; }
  if num.trailing_zeros(0) != 64 { return 7; }

  return 0;
}
