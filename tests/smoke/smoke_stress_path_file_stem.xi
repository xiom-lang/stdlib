// XIOM stdlib stress — xiom.path Path.file_stem extraction
// Tests file_stem() for files with single and multiple extensions.
// Returns 0 on success, nonzero on failure.

module smoke_stress_path_file_stem
use xiom.path;

fn main() -> Int {
  var p1 = path.Path.new("/src/main.xi");
  var p2 = path.Path.new("lib.tar.gz");
  var p3 = path.Path.new("no_ext_here");
  var p4 = path.Path.new(".gitignore");

  match p1.file_stem() {
    Some(stem) => { if stem != "main" { return 1; } }
    None => { return 1; }
  }
  match p2.file_stem() {
    Some(stem) => { if stem != "lib.tar" { return 2; } }
    None => { return 2; }
  }
  match p3.file_stem() {
    Some(stem) => { if stem != "no_ext_here" { return 3; } }
    None => { return 3; }
  }
  match p4.file_stem() {
    Some(stem) => { if stem != ".gitignore" { return 4; } }
    None => { return 4; }
  }

  return 0;
}
