module smoke_probe_gen3
use xiom.io;

fn g_count[T](v: &Vec[T]) -> Int {
  v.len()
}
fn g_take[T](v: &Vec[T], n: Int) -> Vec[T] {
  var out = Vec[T].new();
  var i = 0;
  while i < n && i < v.len() {
    out.push(v[i]);
    i = i + 1;
  }
  out
}

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(1); v.push(2); v.push(3);
  if g_count(&v) != 3 { io.println("c:bad"); return 1; }
  var t = g_take(&v, 2);
  if t.len() != 2 || t[1] != 2 { io.println("t:bad"); return 2; }
  io.println("OK");
  return 0;
}
