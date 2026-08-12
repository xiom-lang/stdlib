module smoke_probe_sv2
use xiom.misc.semver;
use xiom.io;

fn main() -> Int {
  var v = semver_parse("1.2.3-alpha.1");
  match v {
    Some(sv) => {
      if sv.major != 1 { io.println("maj"); return 1; }
      if sv.prerelease != "alpha.1" { io.println("pre"); return 2; }
    },
    None => { io.println("none-a"); return 3; },
  }
  var w = semver_parse("1.2.3+build.7");
  match w {
    Some(sv) => {
      if sv.build != "build.7" { io.println("bld"); return 4; }
    },
    None => { io.println("none-b"); return 5; },
  }
  var u = semver_parse("1.2.3-alpha.1+build.7");
  match u {
    Some(sv) => {
      if sv.prerelease != "alpha.1" { io.println("pre2"); return 6; }
      if sv.build != "build.7" { io.println("bld2"); return 7; }
    },
    None => { io.println("none-c"); return 8; },
  }
  io.println("OK");
  return 0;
}
