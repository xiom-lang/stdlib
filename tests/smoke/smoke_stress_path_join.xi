// XIOM stdlib stress — xiom.path Path.join creates PathBuf with child component
// Tests join with various child path segments.
// Returns 0 on success, nonzero on failure.

module smoke_stress_path_join
use xiom.path;

fn main() -> Int {
  var p = path.Path.new("/home/user");

  var joined1 = p.join("docs");
  if joined1.as_path().to_str() != "/home/user" + path.path_separator() + "docs" { return 1; }

  var joined2 = p.join("src/main.xi");
  if joined2.as_path().to_str() != "/home/user" + path.path_separator() + "src/main.xi" { return 2; }

  var joined3 = p.join("a").join("b").join("c");
  if joined3.as_path().to_str() != "/home/user" + path.path_separator() + "a" + path.path_separator() + "b" + path.path_separator() + "c" { return 3; }

  return 0;
}
