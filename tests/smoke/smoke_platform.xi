module smoke_platform
use xiom.platform;

fn main() -> Int {
  if !(xiom.platform.is_windows() || xiom.platform.is_linux()) { return 1; }
  if !xiom.platform.is_64bit() { return 1; }
  var nl = xiom.platform.newline();
  if nl.len() == 0 { return 1; }
  var sep = xiom.platform.path_sep();
  if sep.len() == 0 { return 1; }
  if xiom.platform.cpu_count() <= 0 { return 1; }
  return 0;
}
