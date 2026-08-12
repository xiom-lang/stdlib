module smoke_probe_svm3
use xiom.misc.semver;
use xiom.io;

fn main() -> Int {
  if !semver_matches("1.5.0", "1.2.3") { io.println("exact"); return 1; }
  if !semver_matches("1.5.0", "1.2.x") { io.println("wild"); return 2; }
  if !semver_matches("1.5.0", ">1.0.0") { io.println("gt"); return 3; }
  if !semver_matches("1.5.0", ">=1.0.0") { io.println("ge"); return 4; }
  if !semver_matches("1.5.0", "~1.2.3") { io.println("tilde"); return 5; }
  if !semver_matches("1.5.0", "^1.2.3") { io.println("caret"); return 6; }
  io.println("OK");
  return 0;
}
