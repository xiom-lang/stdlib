// XIOM stdlib smoke test — xiom.num
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_num
use xiom.num;

fn main() -> Int {
  if num.gcd(12, 8) == 4 && num.lcm(12, 8) == 24 && num.is_power_of_two(64) {
    return 0;
  }
  return 1;
}
