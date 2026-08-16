// XIOM stdlib stress — io.parent_path / file_name / extension
// Tests path decomposition functions on a sample path string.
// Returns 0 on success, nonzero on failure.

module smoke_stress_io_parent_file_name
use xiom.io;
use xiom.path;

fn main() -> Int {
  var p = path.Path.new("/home/user/file.txt");
  match p.file_name() {
    Some(name) => {
      if name != "file.txt" { return 1; }
    }
    None => { return 2; }
  }
  match p.extension() {
    Some(ext) => {
      if ext != "txt" { return 3; }
    }
    None => { return 4; }
  }
  var par_opt = p.parent();
  match par_opt {
    Some(par) => {
      var par_s = par.to_str();
      if par_s == "/home/user" || par_s == "\\home\\user" { return 0; } else { return 5; }
    }
    None => { return 6; }
}
