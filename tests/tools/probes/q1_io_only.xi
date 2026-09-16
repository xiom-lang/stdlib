// q1_io_only.xi -- import ONLY xiom.io to surface io.xi catalog warnings.
module q1_io_only
use xiom.io;

fn main() -> Int {
  io.println("q1-io");
  return 0;
}
