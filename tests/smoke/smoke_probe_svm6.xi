module smoke_probe_svm6
use xiom.string;
use xiom.io;

fn main() -> Int {
  var g = xiom.string.str_split("1.2.3", " ");
  if g.len() != 1 { io.println("glen"); return 1; }
  var g0 = g[0];
  if xiom.string.str_len(g0) != 5 { io.println("g0len"); return 2; }
  var p = xiom.string.str_split("1", ".");
  if p.len() != 1 { io.println("plen"); return 3; }
  var p0 = p[0];
  if xiom.string.str_len(p0) != 1 { io.println("p0len"); return 4; }
  var r = xiom.string.str_to_int(p0);
  match r {
    Ok(val) => { if val != 1 { io.println("val"); return 5; } },
    Err(_) => { io.println("err"); return 6; },
  }
  io.println("OK");
  return 0;
}
