module smoke_probe_svm4
use xiom.misc.semver;
use xiom.io;

fn main() -> Int {
  if semver_matches("1.5.0", "1.2.3") { io.println("exact1"); return 1; }
  if !semver_matches("1.2.3", "1.2.3") { io.println("exact2"); return 2; }
  if !semver_matches("1.5.0", "1.2.x") { io.println("wild"); return 3; }
  if !semver_matches("1.5.0", "1.x") { io.println("wild2"); return 4; }
  if !semver_matches("1.5.0", ">1.0.0") { io.println("gt"); return 5; }
  if !semver_matches("1.5.0", ">=1.0.0") { io.println("ge"); return 6; }
  if semver_matches("1.0.0", ">1.0.0") { io.println("gt2"); return 7; }
  if !semver_matches("1.5.0", "~1.2.3") { io.println("tilde"); return 8; }
  if !semver_matches("1.5.0", "^1.2.3") { io.println("caret"); return 9; }
  if semver_matches("2.0.0", "^1.2.3") { io.println("caret2"); return 10; }
  if !semver_matches("1.2.3", ">=1.0.0 <2.0.0") { io.println("and"); return 11; }
  if semver_matches("2.5.0", ">=1.0.0 <2.0.0") { io.println("and2"); return 12; }
  io.println("OK");
  return 0;
}
