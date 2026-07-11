// XIOM stdlib smoke test — xiom.path
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_path
use xiom.path;

fn main() -> Int {
  let p = path.Path.new("/home/user.txt");
  let name = p.file_name();
  if name.unwrap() == "user.txt" {
    return 0;
  }
  return 1;
}
