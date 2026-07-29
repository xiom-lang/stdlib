module smoke_stress_path_has_root
use xiom.path;

fn main() -> Int {
  var abs = path.Path.new("/home/user/file.txt");
  var rel = path.Path.new("relative/path");
  if abs.has_root() {
    if not rel.has_root() { return 0; } else { return 2; }
  } else { return 1; }
}
