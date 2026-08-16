// XIOM stdlib stress — io.metadata on a regular file
// Writes a file, queries metadata, verifies is_file and size > 0.
// Returns 0 on success.

module smoke_stress_io_metadata
use xiom.io;

fn main() -> Int {
  var path = "__smk_meta.txt";
  io.write_file(path, "metadata test");
  var md = io.metadata(path);
  io.remove_file(path);
  match md {
    Ok(m) => {
      if m.is_file && m.size > 0 { return 0; } else { return 1; }
    }
    Err(_) => { return 2; }
  }
}
