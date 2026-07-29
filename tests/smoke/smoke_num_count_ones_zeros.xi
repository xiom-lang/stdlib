module smoke_num_count_ones_zeros
use xiom.num;

fn main() -> Int {
  if num.count_ones(0) != 0 { return 1; }
  if num.count_ones(1) != 1 { return 2; }
  if num.count_ones(7) != 3 { return 3; }
  if num.count_ones(15) != 4 { return 4; }
  if num.count_ones(255) != 8 { return 5; }

  if num.count_zeros(0) != 64 { return 6; }
  if num.count_zeros(1) != 63 { return 7; }
  if num.count_zeros(7) != 61 { return 8; }

  return 0;
}
