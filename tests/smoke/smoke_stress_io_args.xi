// XIOM stdlib stress -- io.args returns at least program name
// Verifies that args vector has at least 1 element (the binary path).
// Returns 0 on success.

module smoke_stress_io_args
use xiom.io;

fn main() -> Int {
  var a = io.args();
  if a.len() >= 1 { return 0; } else { return 1; }
}
