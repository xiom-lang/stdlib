module smoke_io_std_streams
use xiom.io;

fn main() -> Int {
  let s_in = io.stdin();
  if s_in < 0 { return 1; }

  let s_out = io.stdout();
  if s_out < 0 { return 2; }

  let s_err = io.stderr();
  if s_err < 0 { return 3; }

  return 0;
}
