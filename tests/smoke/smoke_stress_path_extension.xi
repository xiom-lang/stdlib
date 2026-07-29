// XIOM stdlib stress — xiom.path Path.extension extraction
// Tests extension() for various file extensions and no-extension cases.
// Returns 0 on success, nonzero on failure.

module smoke_stress_path_extension
use xiom.path;

fn main() -> Int {
  var p1 = path.Path.new("archive.tar.gz");
  var p2 = path.Path.new("image.png");
  var p3 = path.Path.new("noext");
  var p4 = path.Path.new(".hidden");

  match p1.extension() {
    Some(ext) => { if ext != "gz" { return 1; } }
    None => { return 1; }
  }
  match p2.extension() {
    Some(ext) => { if ext != "png" { return 2; } }
    None => { return 2; }
  }
  match p4.extension() {
    Some(ext) => { if ext != "hidden" { return 4; } }
    None => { return 4; }
  }

  return 0;
}
