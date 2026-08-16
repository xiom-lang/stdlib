// XIOM stdlib stress — io.append_file concatenation
// Writes first part, appends second, verifies concatenated content.
// Returns 0 on success.

module smoke_stress_io_append_file
use xiom.io;

fn main() -> Int {
  var path = "__smk_append.txt";
  io.write_file(path, "first");
  io.append_file(path, "-second");
  var rd = io.read_file(path);
  io.remove_file(path);
  match rd {
    Ok(s) => {
      if s == "first-second" { return 0; } else { return 1; }
    }
    Err(_) => { return 2; }
  }
}
