module smoke_probe_quick
use xiom.sort.quick;
use xiom.io;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(3); v.push(1); v.push(2);
  quick_sort(&mut v);
  if !(v[0] == 1 && v[1] == 2 && v[2] == 3) { io.println("q:bad"); return 1; }
  return 0;
}
