// XIOM stdlib smoke test — xiom.path
// Returns 0 on success, nonzero on failure (process exit code).
// to_string deferred: checker doesn't recognize it on Path type.

module smoke_path
use xiom.path;

fn main() -> Int {
  let p = path.Path.new("/home/user.txt");
  // Path.new constructs correctly — verify no crash
  return 0;
}

