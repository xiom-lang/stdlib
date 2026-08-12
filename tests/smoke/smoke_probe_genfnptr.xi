module smoke_probe_genfnptr
use xiom.io;

fn inc(x: Int) -> Int {
  x + 1
}
fn apply[T](f: fn(&T) -> T, x: &T) -> T {
  var y = *x;
  f(&y)
}
fn inc_ref(x: &Int) -> Int {
  *x + 1
}

fn main() -> Int {
  var z = 41;
  var y = apply(inc_ref, &z);
  if y != 42 { io.println("gfp:bad"); return 1; }
  io.println("OK");
  return 0;
}
