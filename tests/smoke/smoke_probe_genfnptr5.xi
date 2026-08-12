module smoke_probe_genfnptr5
use xiom.io;

fn inc(x: Int) -> Int {
  x + 1
}
fn my_loop[T](x: T, f: fn(T) -> T, n: Int) -> T {
  var acc = x;
  var i = 0;
  while i < n {
    acc = f(acc);
    i = i + 1;
  }
  acc
}
fn my_ref[T](x: &T, f: fn(&T) -> T) -> T {
  var y = *x;
  f(&y)
}
fn inc_ref(x: &Int) -> Int {
  *x + 1
}

fn main() -> Int {
  var a = my_loop(0, inc, 5);
  if a != 5 { io.println("l:bad"); return 1; }
  var z = 41;
  var b = my_ref(&z, inc_ref);
  if b != 42 { io.println("r:bad"); return 2; }
  io.println("OK");
  return 0;
}
