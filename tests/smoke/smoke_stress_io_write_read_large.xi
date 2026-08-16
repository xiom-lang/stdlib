// XIOM stdlib stress — io.write_file / io.read_file large content
// Writes multi-line repeated content, reads it back, verifies.
// Returns 0 on success, nonzero on failure.

module smoke_stress_io_write_read_large
use xiom.io;

fn main() -> Int {
  var s = "0123456789";
  var big = s + s + s + s + s + s + s + s + s + s;
  var path = "__smk_io_large.txt";
  io.write_file(path, big);
  var rd = io.read_file(path);
  io.remove_file(path);
  match rd {
    Ok(data) => {
      if data == big { return 0; } else { return 1; }
    }
    Err(_) => { return 2; }
}
