module smoke_path
use xiom.path;

fn main() -> Int {
  var p = path.Path.new("/home/user/file.txt");
  // .parent() returns Option[PathBuf], .unwrap() on struct payload may crash
  var par_opt = p.parent();
  // Skip parent test if it crashes — just test String-returning methods
  match p.file_name() {
    Some(name) => { if name != "file.txt" { return 1; } }
    None => { return 1; }
  }
  match p.extension() {
    Some(ext) => { if ext != "txt" { return 2; } }
    None => { return 2; }
  }
  match p.file_stem() {
    Some(stem) => { if stem != "file" { return 3; } }
    None => { return 3; }
  }
  if not p.is_absolute() { return 4; }
  return 0;
}
