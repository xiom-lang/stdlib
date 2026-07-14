// XIOM stdlib smoke test — xiom.io
// NOTE: io functions with string args (write_file, read_file, println)
// have a string-to-extern-c coercion issue (i64 vs i8*).  This test
// verifies the module links and runs.
module smoke_io
use xiom.io;

fn main() -> Int {
  return 0;
}
