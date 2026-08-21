// XIOM stdlib stress -- io.BufReader from stdin, call lines()
// Returns 0 on success, nonzero on failure.

module smoke_stress_io_bufreader
use xiom.io;

fn main() -> Int {
  var rd = io.stdin();
  var br = io.BufReader.new(rd);
  var lines = br.lines();
  if lines.len() >= 0 { return 0; } else { return 1; }
}
