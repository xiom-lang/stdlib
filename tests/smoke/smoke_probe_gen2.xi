module smoke_probe_gen2
use xiom.io;

fn g_sort[T: Ord](v: &Vec[T]) -> Vec[T] {
  var out = Vec[T].new();
  var i = 0;
  while i < v.len() {
    out.push(v[i]);
    i = i + 1;
  }
  var j = 1;
  while j < out.len() {
    var k = j;
    while k > 0 && out[k - 1].compare(&out[k]) > 0 {
      var t = out[k - 1];
      out[k - 1] = out[k];
      out[k] = t;
      k = k - 1;
    }
    j = j + 1;
  }
  out
}
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
fn g_zip[T, U](a: &Vec[T], b: &Vec[U]) -> Vec[(T, U)] {
  var out = Vec[(T, U)].new();
  var n = a.len();
  if b.len() < n { n = b.len(); }
  var i = 0;
  while i < n {
    out.push((a[i], b[i]));
    i = i + 1;
  }
  out
}
fn g_repeat[T](item: T, n: Int) -> Vec[T] {
  var out = Vec[T].new();
  var i = 0;
  while i < n {
    out.push(item);
    i = i + 1;
  }
  out
}
fn g_count[T](v: &Vec[T]) -> Int {
  v.len()
}

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(3); v.push(1); v.push(2);
  var s = g_sort(&v);
  if !(s[0] == 1 && s[1] == 2 && s[2] == 3) { io.println("s:bad"); return 1; }
  if !g_eq(&s, &s) { io.println("e:bad"); return 2; }
  var z = g_zip(&v, &s);
  if z.len() != 3 || z[0].0 != 3 || z[0].1 != 1 { io.println("z:bad"); return 3; }
  var r = g_repeat(7, 3);
  if r.len() != 3 || r[2] != 7 { io.println("r:bad"); return 4; }
  if g_count(&v) != 3 { io.println("c:bad"); return 5; }
  io.println("OK");
  return 0;
}
