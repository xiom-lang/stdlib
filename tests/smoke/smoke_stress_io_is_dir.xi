// XIOM stdlib stress — io.is_dir distinguishes file vs directory
// Creates a file and checks is_dir returns false; checks "." is true.
// Returns 0 on success.

module smoke_stress_io_is_dir
use xiom.io;

fn main() -> Int {
  var path = "__smk_isdir.txt";
  io.write_file(path, "test");
  var is_f = io.is_dir(path);
  var is_d = io.is_dir(".");
  io.remove_file(path);
  if not is_f && is_d { return 0; } else { return 1; }
}
