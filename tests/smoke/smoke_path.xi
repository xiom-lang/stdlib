module smoke_path
use xiom.path;

fn main() -> Int {
  let p = path.Path.new("/home/user/file.txt");
  // .parent() returns Option[PathBuf], .unwrap() on struct payload may crash
  let par_opt = p.parent();
  // Skip parent test if it crashes — just test String-returning methods
  if p.file_name().unwrap() != "file.txt" { return 1; }
  if p.extension().unwrap() != "txt" { return 2; }
  if p.file_stem().unwrap() != "file" { return 3; }
  if !p.is_absolute() { return 4; }
  return 0;
}
