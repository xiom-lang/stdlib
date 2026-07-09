// XIOM stdlib smoke test — xiom.mem
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_mem
use xiom.mem;

fn main() -> Int {
  var a = 10;
  var b = 20;
  mem.swap(&mut a, &mut b);
  if a == 20 && b == 10 {
    return 0;
  }
  return 1;
}
