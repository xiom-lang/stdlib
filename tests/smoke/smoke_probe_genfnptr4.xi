module smoke_probe_genfnptr4
use xiom.io;

fn add(a: Int, b: &Int) -> Int {
  a + *b
}
fn my_fold[T](v: &Vec[T], init: T, f: fn(T, &T) -> T) -> T {
  var acc = init;
  var i = 0;
  while i < v.len() {
    var x = v[i];
    acc = f(acc, &x);
    i = i + 1;
  }
  acc
}
fn my_count[T](v: Vec[T], f: fn(&T) -> Bool) -> Int {
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
  var r = Vec[Int].new();
  r.push(1); r.push(2); r.push(3); r.push(4);
  var s = my_fold(&r, 0, add);
  if s != 10 { io.println("f:bad"); return 1; }
  var c = my_count(r, is_even);
  if c != 2 { io.println("c:bad"); return 2; }
  io.println("OK");
  return 0;
}
