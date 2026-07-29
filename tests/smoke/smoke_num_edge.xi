module smoke_num_edge
use xiom.num;

fn main() -> Int {
  if num.gcd(1, 1) != 1 { return 1; }
  if num.lcm(1, 1) != 1 { return 2; }

  if !num.is_power_of_two(536870912) { return 3; }

  if num.leading_zeros(-1) != 0 { return 4; }
  if num.trailing_zeros(-1) != 0 { return 4; }

  if num.count_ones(-1) != 64 { return 5; }

  match num.parse_int_radix("-FF", 16) {
    Ok(n) => { if n != -255 { return 6; } },
    Err(_) => { return 7; },
  };
  match num.parse_int_radix("+10", 10) {
    Ok(n) => { if n != 10 { return 8; } },
    Err(_) => { return 9; },
  };

  return 0;
}
