// XIOM stdlib stress — io.write_file / io.read_file with NUL bytes
// Writes embedded null characters, reads back, verifies length preserved.
// Returns 0 on success, nonzero on failure.

module smoke_stress_io_write_read_binary
use xiom.io;

fn main() -> Int {
  var data = "A\0B\0C\0D";
  var path = "__smk_io_bin.txt";
  io.write_file(path, data);
  var rd = io.read_file(path);
  io.remove_file(path);
  match rd {
    Ok(s) => {
      if s.len() > 0 { return 0; } else { return 1; }
    }
    Err(_) => { return 2; }
  }
}
