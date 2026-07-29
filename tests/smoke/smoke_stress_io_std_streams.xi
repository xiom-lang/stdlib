// XIOM stdlib stress — io.stdin / io.stdout / io.stderr descriptors
// Verifies all three standard stream descriptors are non-negative.
// Returns 0 on success.

module smoke_stress_io_std_streams
use xiom.io;

fn main() -> Int {
  var sin = io.stdin();
  var sout = io.stdout();
  var serr = io.stderr();
  if sin >= 0 && sout >= 0 && serr >= 0 { return 0; } else { return 1; }
}
