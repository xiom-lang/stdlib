module smoke_probe_svm5
use xiom.misc.semver;
use xiom.io;

fn main() -> Int {
  if !semver_matches("1.2.3", "1") { io.println("m1"); return 1; }
  if !semver_matches("1.2.3", "1.2") { io.println("m2"); return 2; }
  if !semver_matches("1.2.3", "1.2.3") { io.println("m3"); return 3; }
  if semver_matches("1.2.4", "1.2.3") { io.println("m4"); return 4; }
  io.println("OK");
  return 0;
}
