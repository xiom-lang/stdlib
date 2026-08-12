module smoke_probe_svm
use xiom.misc.semver;
use xiom.io;

fn main() -> Int {
  if !semver_matches("1.5.0", "^1.2.3") { io.println("a"); return 1; }
  if semver_matches("2.0.0", "^1.2.3") { io.println("b"); return 2; }
  if !semver_matches("1.2.5", "~1.2.3") { io.println("c"); return 3; }
  if semver_matches("1.3.0", "~1.2.3") { io.println("d"); return 4; }
  if !semver_matches("1.2.3", ">=1.0.0 <2.0.0") { io.println("e"); return 5; }
  if semver_matches("2.5.0", ">=1.0.0 <2.0.0") { io.println("f"); return 6; }
  if !semver_matches("1.2.3", "1.2.3") { io.println("g"); return 7; }
  if semver_matches("1.2.4", "1.2.3") { io.println("h"); return 8; }
  if !semver_matches("1.3.0", "1.x") { io.println("i"); return 9; }
  if !semver_matches("1.2.9", "1.2.x") { io.println("j"); return 10; }
  io.println("OK");
  return 0;
}
