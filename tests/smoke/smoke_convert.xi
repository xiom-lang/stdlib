// XIOM stdlib smoke test — xiom.convert
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_convert
use xiom.convert;

fn main() -> Int {
  if convert.int_to_string(42) == "42" && convert.int_to_float(42) == 42.0 && convert.float_to_int(3.7) == 3 {
    return 0;
  }
  return 1;
}
