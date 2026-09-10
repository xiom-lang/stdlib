// XIOM stdlib stress -- io.set_permissions on temp file
// Creates a test file, sets permissions, cleans up, verifies result.
// Returns 0 on success, nonzero on failure.

module smoke_stress_io_set_permissions
use xiom.io;

fn main() -> Int {
  var path = "__smk_perm.txt";
  // Pre-clean: heal leftovers from previous runs that aborted before cleanup.
  var _pre = io.remove_file(path);
  var _wr = io.write_file(path, "test");
  // 420 == 0o644 (rw-r--r--): exercising set_permissions with a mode that
  // keeps the file removable; mode 0 makes it read-only and removal fails.
  var sp = io.set_permissions(path, 420);
  var _ = io.remove_file(path);
  match sp {
    Ok(_) => { return 0; }
    Err(_) => { return 1; }
  }
}
