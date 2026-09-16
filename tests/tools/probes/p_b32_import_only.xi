module p_b32_import_only
use xiom.convert.base32;
use xiom.io;

fn main() -> Int {
  io.println("IMPORT-ONLY OK");
  io.flush_stdout();
  return 0;
}
