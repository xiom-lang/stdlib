module smoke_probe_sv6
use xiom.string;
use xiom.io;

fn main() -> Int {
  var text = "1.2.3-alpha";
  var core = text;
  var dash = xiom.string.str_index_of(core, "-");
  match dash {
    Some(pos) => {
      var pre = xiom.string.str_slice(core, pos + 1, core.len());
      core = xiom.string.str_slice(core, 0, pos);
      if pre != "alpha" { io.println("pre"); return 1; }
      if core != "1.2.3" { io.println("core"); return 2; }
      var parts = xiom.string.str_split(core, ".");
      if parts.len() != 3 { io.println("plen"); return 3; }
    },
    None => { io.println("none"); return 4; },
  }
  io.println("OK");
  return 0;
}
