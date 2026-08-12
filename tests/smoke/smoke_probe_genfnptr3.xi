module smoke_probe_genfnptr3
use xiom.io;

fn is_even(x: &Int) -> Bool {
  *x % 2 == 0
}
fn my_count[T](v: &Vec[T], f: fn(&T) -> Bool) -> Int {
  var c = 0;
  var i = 0;
  while i < v.len() {
    var x = v[i];
    if f(&x) { c = c + 1; }
    i = i + 1;
  }
  c
}

fn main() -> Int {
  var r = Vec[Int].new();
  r.push(1); r.push(2); r.push(3); r.push(4);
  var c = my_count(&r, is_even);
  if c != 2 { io.println("c:bad"); return 3; }
  io.println("OK");
  return 0;
}
