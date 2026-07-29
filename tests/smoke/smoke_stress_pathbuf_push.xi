// XIOM stdlib stress — xiom.path PathBuf push and as_path
// Tests PathBuf construction, push, and conversion to Path.
// Returns 0 on success, nonzero on failure.

module smoke_stress_pathbuf_push
use xiom.path;

fn main() -> Int {
  var buf = path.PathBuf.new();
  buf.push("home");
  buf.push("user");
  buf.push("projects");
  var p = buf.as_path();
  if p.to_str() != "home/user/projects" { return 1; }

  var buf2 = path.PathBuf.from("/tmp");
  buf2.push("log.txt");
  var p2 = buf2.as_path();
  if p2.to_str() != "/tmp/log.txt" { return 2; }

  var sep = path.path_separator();
  if sep.len() == 0 { return 3; }

  return 0;
}
