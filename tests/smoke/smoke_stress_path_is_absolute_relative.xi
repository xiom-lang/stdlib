// XIOM stdlib stress -- xiom.path Path.is_absolute and is_relative
// Tests absolute/relative detection on multiple path styles.
// Returns 0 on success, nonzero on failure.

module smoke_stress_path_is_absolute_relative
use xiom.path;

fn main() -> Int {
  var abs1 = path.Path.new("/usr/bin");
  var abs2 = path.Path.new("/");
  var rel1 = path.Path.new("src/main.xi");
  var rel2 = path.Path.new("../parent/file");
  var rel3 = path.Path.new(".");

  if not abs1.is_absolute() { return 1; }
  if not abs2.is_absolute() { return 2; }
  if abs1.is_relative() { return 3; }
  if abs2.is_relative() { return 4; }

  if not rel1.is_relative() { return 5; }
  if not rel2.is_relative() { return 6; }
  if not rel3.is_relative() { return 7; }
  if rel1.is_absolute() { return 8; }
  if rel2.is_absolute() { return 9; }
  if rel3.is_absolute() { return 10; }

  return 0;
}
