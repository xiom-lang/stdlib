// XIOM stdlib stress -- io.remove_file success and verification
// Writes file, removes it, verifies file is gone.
// Returns 0 on success.

module smoke_stress_io_remove_file
use xiom.io;

fn main() -> Int {
  var path = "__smk_remove.txt";
  io.write_file(path, "data");
  io.remove_file(path);
  if io.file_exists(path) { return 1; } else { return 0; }
}
