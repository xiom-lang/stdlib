module smoke_probe_svm8
use xiom.misc.semver;
use xiom.io;

fn main() -> Int {
  match semver_parse("1.2.3") {
    Some(a) => {
      match semver_parse("1.10.0") {
        Some(b) => {
          var c = semver_compare(a, b);
          if c >= 0 { io.println("cmp"); return 1; }
        },
        None => { io.println("n2"); return 2; },
      }
    },
    None => { io.println("n1"); return 3; },
  }
  if !semver_valid("1.2.3") { io.println("val"); return 4; }
  io.println("OK");
  return 0;
}
