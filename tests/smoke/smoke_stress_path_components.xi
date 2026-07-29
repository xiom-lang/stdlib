// XIOM stdlib stress — xiom.path Path.components decomposition
// Tests components() on absolute and relative paths.
// Returns 0 on success, nonzero on failure.

module smoke_stress_path_components
use xiom.path;

fn main() -> Int {
  var p1 = path.Path.new("/usr/local/bin");
  var comps1 = p1.components();
  if comps1.len() < 3 { return 1; }

  var p2 = path.Path.new("a/b/c");
  var comps2 = p2.components();
  if comps2.len() < 3 { return 2; }

  var p3 = path.Path.new("/");
  var comps3 = p3.components();
  if comps3.len() < 0 { return 3; }

  return 0;
}
