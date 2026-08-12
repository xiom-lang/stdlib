module smoke_probe_fnptr
use xiom.io;

fn inc(x: Int) -> Int {
  x + 1
}
fn apply(f: fn(Int) -> Int, x: Int) -> Int {
  f(x)
}

fn main() -> Int {
  var y = apply(inc, 41);
  if y != 42 { io.println("fp:bad"); return 1; }
  io.println("OK");
  return 0;
}
