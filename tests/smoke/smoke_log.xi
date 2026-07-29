// XIOM stdlib smoke test — xiom.log
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_log
use xiom.log;

fn main() -> Int {
  xiom.log.set_level(xiom.log.LogLevel.Warn);
  var lvl = xiom.log.get_level();
  if lvl == xiom.log.LogLevel.Warn {
    return 0;
  }
  return 1;
}
