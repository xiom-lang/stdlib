module smoke_probe_s13
use xiom.search.binary;
use xiom.search.linear;
use xiom.io;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(1); v.push(3); v.push(5);
  var r = xiom.search.binary.binary_search(&v, 5);
  match r {
    Some(i) => { if i != 2 { io.println("b:idx"); return 1; } },
    None => { io.println("b:none"); return 2; },
  }
  if xiom.search.binary.lower_bound(&v, 5) != 2 { io.println("lb:bad"); return 3; }
  var ls = xiom.search.linear.linear_search(&v, 3);
  match ls {
    Some(i) => { if i != 1 { io.println("ls:idx"); return 4; } },
    None => { io.println("ls:none"); return 5; },
  }
  io.println("OK");
  return 0;
}

