module smoke_probe_genfnptr6
use xiom.io;

fn inc_ref(x: &Int) -> Int {
  *x + 1
}
fn my_make[T](f: fn(&T) -> T, x: &T) -> Vec[T] {
  var out = Vec[T].new();
  var y = *x;
  out.push(f(&y));
  out
}
fn my_loop2[T](v: Vec[T], f: fn(&T) -> Bool) -> Int {
  var c = 0;
  var i = 0;
  while i < v.len() {
    var x = v[i];
    if f(&x) { c = c + 1; }
    i = i + 1;
  }
  c
}
fn is_even(x: &Int) -> Bool {
  *x % 2 == 0
}

fn main() -> Int {
  var z = 41;
  var m = my_make(inc_ref, &z);
  if m.len() != 1 || m[0] != 42 { io.println("mk:bad"); return 1; }
  var r = Vec[Int].new();
  r.push(1); r.push(2); r.push(3); r.push(4);
  var c = my_loop2(r, is_even);
  if c != 2 { io.println("lp:bad"); return 2; }
  io.println("OK");
  return 0;
}
