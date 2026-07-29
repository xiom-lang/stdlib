module smoke_io_args
use xiom.io;

fn main() -> Int {
  var args = io.args();
  if args.len() < 1 { return 1; }

  return 0;
}
