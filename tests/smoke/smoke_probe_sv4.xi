module smoke_probe_sv4
use xiom.string;
use xiom.io;

fn main() -> Int {
  var i = xiom.string.str_index_of("1.2.3-alpha", "-");
  match i {
    Some(pos) => {
      if pos != 5 { io.println("pos"); return 1; }
      var pre = xiom.string.str_slice("1.2.3-alpha", pos + 1, 11);
      if pre != "alpha" { io.println("pre"); return 2; }
      var core = xiom.string.str_slice("1.2.3-alpha", 0, pos);
      if core != "1.2.3" { io.println("core"); return 3; }
    },
    None => { io.println("none"); return 4; },
  }
  io.println("OK");
  return 0;
}
