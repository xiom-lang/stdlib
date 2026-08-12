module smoke_probe_svc6
use xiom.misc.glob;
use xiom.misc.levenshtein;
use xiom.misc.natural;
use xiom.misc.semver;
use xiom.misc.soundex;
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
