// XIOM stdlib stress — io.set_permissions on temp file
// Creates a test file, sets permissions, cleans up, verifies result.
// Returns 0 on success, nonzero on failure.

module smoke_stress_io_set_permissions
use xiom.io;

fn main() -> Int {
  var path = "__smk_perm.txt";
  var _wr = io.write_file(path, "test");
  var sp = io.set_permissions(path, 0);
  var _ = io.remove_file(path);
  match sp {
    Ok(_) => { return 0; }
    Err(_) => { return 1; }
  }
}
