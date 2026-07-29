module smoke_stress_path_separator
use xiom.path;

fn main() -> Int {
  var sep = path.path_separator();
  if sep.len() > 0 { return 0; } else { return 1; }
}
