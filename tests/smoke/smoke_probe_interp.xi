module smoke_probe_interp
use xiom.search.interpolation;
use xiom.io;

fn main() -> Int {

  var v = Vec[Int].new();
  v.push(1); v.push(3); v.push(5);
  var r = interpolation_search(&v, 5);
  match r {
    Some(i) => { if i != 2 { io.println("i:idx"); return 1; } },
    None => { io.println("i:none"); return 2; },
  }
  io.println("OK");
  return 0;
}

