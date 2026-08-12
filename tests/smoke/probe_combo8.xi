module probe_combo8
use xiom.os.platform;
use xiom.os.term;
use xiom.io;
fn main() -> Int {
  var reset = term.term_reset();
  io.println("reset-len=" + reset.len().to_str());
  0
}
