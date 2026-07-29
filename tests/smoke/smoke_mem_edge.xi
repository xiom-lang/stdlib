module smoke_mem_edge
use xiom.mem;

fn main() -> Int {
  var a: Int = 1;
  var b: Int = 2;
  mem.swap(&mut a, &mut b);
  mem.swap(&mut a, &mut b);
  if a != 1 { return 1; }
  if b != 2 { return 2; }

  var c: Int = 5;
  var old = mem.replace(&mut c, c);
  if old != 5 { return 3; }
  if c != 5 { return 4; }

  return 0;
}
