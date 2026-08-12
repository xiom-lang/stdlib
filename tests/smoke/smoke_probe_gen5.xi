module smoke_probe_gen5
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

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(3); v.push(1); v.push(2);
  var s = g_sort(&v);
  if !(s[0] == 1 && s[1] == 2 && s[2] == 3) { io.println("s:bad"); return 1; }
  io.println("OK");
  return 0;
}
