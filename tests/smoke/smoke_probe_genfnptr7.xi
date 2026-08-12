module smoke_probe_genfnptr7
use xiom.io;

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
  r.push(1); r.push(2);
  if r.len() != 2 { io.println("l:bad"); return 1; }
  io.println("OK");
  return 0;
}
