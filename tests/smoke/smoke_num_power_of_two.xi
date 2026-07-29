module smoke_num_power_of_two
use xiom.num;

fn main() -> Int {
  if !num.is_power_of_two(1) { return 1; }
  if !num.is_power_of_two(2) { return 2; }
  if !num.is_power_of_two(4) { return 3; }
  if !num.is_power_of_two(1024) { return 4; }
  if num.is_power_of_two(0) { return 5; }
  if num.is_power_of_two(3) { return 6; }
  if num.is_power_of_two(6) { return 7; }
  if num.is_power_of_two(-1) { return 8; }

  if num.next_power_of_two(1) != 1 { return 9; }
  if num.next_power_of_two(3) != 4 { return 10; }
  if num.next_power_of_two(5) != 8 { return 11; }
  if num.next_power_of_two(9) != 16 { return 12; }
  if num.next_power_of_two(0) != 1 { return 13; }
  if num.next_power_of_two(-5) != 1 { return 14; }

  return 0;
}
