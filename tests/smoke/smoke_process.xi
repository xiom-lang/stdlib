module smoke_process
use xiom.process;
fn main() -> Int {
  var pid = xiom.process.get_pid();
  if pid <= 0 { return 1; }
  return 0;
}
