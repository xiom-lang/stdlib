module smoke_stress_path_starts_ends_with
use xiom.path;

fn main() -> Int {
  var p = path.Path.new("/usr/local/bin/xiom");
  if p.starts_with(path.Path.new("/usr")) {
    if p.ends_with(path.Path.new("xiom")) { return 0; } else { return 2; }
  } else { return 1; }
}
