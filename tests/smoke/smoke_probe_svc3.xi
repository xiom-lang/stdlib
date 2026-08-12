module smoke_probe_svc3
use xiom.misc.semver;
use xiom.misc.natural;
use xiom.io;

fn main() -> Int {
  var v = semver_parse("1.2.3");
  match v {
    Some(sv) => {
      if sv.major != 1 { io.println("maj"); return 1; }
    },
    None => { io.println("none"); return 2; },
  }
  io.println("OK");
  return 0;
}

