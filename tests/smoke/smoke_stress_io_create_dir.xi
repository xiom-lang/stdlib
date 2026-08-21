// XIOM stdlib stress -- io.create_dir / io.is_dir
// Creates a directory, confirms is_dir returns true, cleans up.
// Returns 0 on success.

module smoke_stress_io_create_dir
use xiom.io;

fn main() -> Int {
  var dir = "__smk_testdir";
  var _ = io.remove_file(dir);
  io.create_dir(dir);
  var isd = io.is_dir(dir);
  io.remove_file(dir);
  if isd { return 0; } else { return 1; }
}
