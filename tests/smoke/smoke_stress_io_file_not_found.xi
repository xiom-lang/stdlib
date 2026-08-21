// XIOM stdlib stress -- io.read_file on non-existent path
// Expects Err result; returns 0 if Err, 1 if Ok (unexpected).
// Returns 0 on success.

module smoke_stress_io_file_not_found
use xiom.io;

fn main() -> Int {
  var rd = io.read_file("__nonexistent_file_xyz123.xyz");
  match rd {
    Ok(_) => { return 1; }
    Err(_) => { return 0; }
  }
}
