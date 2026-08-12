module smoke_probe_gen4
use xiom.io;

fn g_eq[T: Eq](a: &Vec[T], b: &Vec[T]) -> Bool {
  if a.len() != b.len() { return false; }
  var i = 0;
  while i < a.len() {
    var x = a[i];
    var y = b[i];
    if !x.eq(&y) { return false; }
    i = i + 1;
  }
  true
}

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(1); v.push(2); v.push(3);
  var w = Vec[Int].new();
  w.push(1); w.push(2); w.push(3);
  if !g_eq(&v, &w) { io.println("e:bad"); return 1; }
  io.println("OK");
  return 0;
}
