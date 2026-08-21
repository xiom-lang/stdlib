// XIOM stdlib stress -- xiom.path Path.with_extension replacement
// Tests with_extension replacing and adding extensions.
// Returns 0 on success, nonzero on failure.

module smoke_stress_path_with_extension
use xiom.path;

fn main() -> Int {
  var p1 = path.Path.new("src/main.xi");
  var changed = p1.with_extension("txt");
  if changed.as_path().to_str() != "src" + path.path_separator() + "main.txt" { return 1; }

  var p2 = path.Path.new("README");
  var added = p2.with_extension("md");
  if added.as_path().to_str() != "README.md" { return 2; }

  var p3 = path.Path.new("archive.tar.gz");
  var swapped = p3.with_extension("bz2");
  if swapped.as_path().to_str() != "archive.tar.bz2" { return 3; }

  return 0;
}
