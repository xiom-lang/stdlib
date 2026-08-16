module smoke_stress_path_with_file_name
use xiom.path;

fn main() -> Int {
  var p = path.Path.new("/usr/bin/old.txt");
  var renamed = p.with_file_name("new.txt");
  var name = renamed.file_name();
  match name {
    Some(n) => {
      if n == "new.txt" { return 0; } else { return 2; }
    }
    None => { return 1; }
}
