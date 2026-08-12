module smoke_probe_sv5
use xiom.misc.semver;
use xiom.io;

fn main() -> Int {
  var w = semver_parse("1.2.3-1");
  match w {
    Some(sv) => { io.println("ok-b"); return 0; },
    None => { io.println("none-b"); return 5; },
  }
}
