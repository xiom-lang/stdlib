module smoke_probe_sv3
use xiom.misc.semver;
use xiom.io;

fn main() -> Int {
  var v = semver_parse("1.2.3-alpha");
  match v {
    Some(sv) => { if sv.prerelease != "alpha" { io.println("pre"); return 1; } },
    None => { io.println("none-a"); return 3; },
  }
  var w = semver_parse("1.2.3-1");
  match w {
    Some(sv) => { if sv.prerelease != "1" { io.println("pre1"); return 4; } },
    None => { io.println("none-b"); return 5; },
  }
  var x = semver_parse("1.2.3-alpha.1");
  match x {
    Some(sv) => { io.println("ok-c"); return 0; },
    None => { io.println("none-c"); return 8; },
  }
}
