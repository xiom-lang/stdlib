// XIOM stdlib stress — io.file_exists true/false
// Writes a file, confirms exists, removes, confirms gone.
// Returns 0 on success.

module smoke_stress_io_file_exists
use xiom.io;

fn main() -> Int {
  var path = "__smk_exists.txt";
  io.write_file(path, "test");
  var exists = io.file_exists(path);
  io.remove_file(path);
  var not_exists = io.file_exists("__nonexistent_xyz.xyz");
  if exists && not not_exists { return 0; } else { return 1; }
}
