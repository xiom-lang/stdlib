module smoke_probe_svc7
use xiom.misc.glob;
use xiom.misc.levenshtein;
use xiom.misc.natural;
use xiom.misc.semver;
use xiom.misc.soundex;
use xiom.io;

fn main() -> Int {
  var v = semver_parse("1.2.3-alpha.1+build.7");
  match v {
    Some(sv) => {
      var txt = semver_to_string(sv);
      if txt != "1.2.3-alpha.1+build.7" { io.println("s19:bad"); return 68; }
      var pre = semver_prerelease(sv);
      match pre {
        Some(p) => { if p != "alpha.1" { io.println("s20:bad"); return 69; } },
        None => { io.println("s21:bad"); return 70; },
      }
    },
    None => { io.println("s28:bad"); return 77; },
  }
  io.println("OK");
  return 0;
}
