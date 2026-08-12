module smoke_probe_svm2
use xiom.string;
use xiom.convert;
use xiom.misc.semver;
use xiom.io;

fn main() -> Int {
  var t = xiom.string.str_slice("^1.2.3", 1, 6);
  io.println(t);
  var parts = xiom.string.str_split("1.2.3", ".");
  if parts.len() != 3 { io.println("plen"); return 1; }
  var r = xiom.string.str_to_int(parts[0]);
  match r {
    Ok(v) => { io.println(convert.int_to_string(v)); },
    Err(_) => { io.println("err"); return 2; },
  }
  if semver_matches("1.5.0", "1.x") { io.println("wild-ok"); } else { io.println("wild-bad"); return 3; }
  if semver_matches("1.5.0", "1.2.3") { io.println("bare-ok"); } else { io.println("bare-bad"); return 4; }
  io.println("OK");
  return 0;
}
