module smoke_probe_genfnptr2
use xiom.io;

fn double(x: &Int) -> Int {
  *x * 2
}
fn my_map[T, U](v: &Vec[T], f: fn(&T) -> U) -> Vec[U] {
  var out = Vec[U].new();
  var i = 0;
  while i < v.len() {
    var x = v[i];
    out.push(f(&x));
    i = i + 1;
  }
  out
}

fn main() -> Int {
  var r = Vec[Int].new();
  r.push(1); r.push(2); r.push(3); r.push(4);
  var m = my_map(&r, double);
  if !(m[0] == 2 && m[1] == 4 && m[2] == 6 && m[3] == 8) { io.println("m:bad"); return 3; }
  io.println("OK");
  return 0;
}
