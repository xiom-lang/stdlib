module smoke_probe_linear
use xiom.search.linear;
use xiom.io;

fn main() -> Int {

  var v = Vec[Int].new();
  v.push(1); v.push(3); v.push(5);
  var r = linear_search(&v, 5);
  match r {
    Some(i) => { if i != 2 { io.println("l:idx"); return 1; } },
    None => { io.println("l:none"); return 2; },
  }
  io.println("OK");
  return 0;
}

