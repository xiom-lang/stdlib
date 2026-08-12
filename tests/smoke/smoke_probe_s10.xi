module smoke_probe_s10
use xiom.search.binary;
use xiom.io;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(1); v.push(3); v.push(5);
  var r = binary_search(&v, 5);
  match r {
    Some(i) => { if i != 2 { io.println("b:idx"); return 1; } },
    None => { io.println("b:none"); return 2; },
  }
  io.println("OK");
  return 0;
}
