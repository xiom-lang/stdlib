// XIOM stdlib stress -- xiom.path Path.file_name extraction
// Tests file_name on paths with and without extensions.
// Returns 0 on success, nonzero on failure.

module smoke_stress_path_file_name
use xiom.path;

fn main() -> Int {
  var p1 = path.Path.new("/dir/file.txt");
  var p2 = path.Path.new("/dir/subdir/");
  var p3 = path.Path.new("Makefile");
  var p4 = path.Path.new("/");

  match p1.file_name() {
    Some(name) => { if name != "file.txt" { return 1; } }
    None => { return 1; }
  }
  match p3.file_name() {
    Some(name) => { if name != "Makefile" { return 3; } }
    None => { return 3; }
  }

  return 0;
}
