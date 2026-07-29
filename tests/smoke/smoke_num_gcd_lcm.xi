module smoke_num_gcd_lcm
use xiom.num;

fn main() -> Int {
  if num.gcd(12, 8) != 4 { return 1; }
  if num.gcd(17, 13) != 1 { return 2; }
  if num.gcd(100, 0) != 100 { return 3; }
  if num.gcd(0, 100) != 100 { return 4; }
  if num.gcd(0, 0) != 0 { return 5; }
  if num.gcd(-12, 8) != 4 { return 0; }

  if num.lcm(4, 6) != 12 { return 6; }
  if num.lcm(21, 6) != 42 { return 7; }
  if num.lcm(0, 5) != 0 { return 8; }
  if num.lcm(7, 0) != 0 { return 9; }
  if num.lcm(1, 1) != 1 { return 10; }

  return 0;
}
