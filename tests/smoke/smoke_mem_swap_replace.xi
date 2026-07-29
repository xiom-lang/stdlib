module smoke_mem_swap_replace
use xiom.mem;

fn main() -> Int {
  var a: Int = 10;
  var b: Int = 20;
  mem.swap(&mut a, &mut b);
  if a != 20 { return 1; }
  if b != 10 { return 2; }

  var old = mem.replace(&mut a, 99);
  if old != 20 { return 3; }
  if a != 99 { return 4; }

  return 0;
}
