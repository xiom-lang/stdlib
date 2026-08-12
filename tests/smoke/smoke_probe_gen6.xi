module smoke_probe_gen6
use xiom.io;

fn g_contains[T: Eq](v: &Vec[T], item: &T) -> Bool {
  var i = 0;
  while i < v.len() {
    var x = v[i];
    if x.eq(item) { return true; }
    i = i + 1;
  }
  false
}
fn g_compare_elems[T: Ord](v: &Vec[T], item: &T) -> Int {
  var x = v[0];
  x.compare(item)
}

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(1); v.push(2); v.push(3);
  if !g_contains(&v, &2) { io.println("c:bad"); return 1; }
  var c = g_compare_elems(&v, &2);
  if c != -1 { io.println("cmp:bad"); return 2; }
  io.println("OK");
  return 0;
}
