// XIOM stdlib stress — io.env_var returns Some for PATH
// Reads the PATH environment variable, expects Some value.
// Returns 0 on success.

module smoke_stress_io_env_var
use xiom.io;

fn main() -> Int {
  var path = io.env_var("PATH");
  match path {
    Some(_) => { return 0; }
    None => { return 1; }
  }
}
