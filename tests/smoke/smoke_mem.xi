module smoke_mem
use xiom.mem;

fn main() -> Int {
  var a = 1;
  var b = 2;
  mem.swap[Int](&mut a, &mut b);
  if a != 2 { return 1; }
  if b != 1 { return 2; }
  return 0;
}
