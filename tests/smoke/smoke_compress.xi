// XIOM stdlib smoke test -- xiom.compress
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_compress
use xiom.compress;

fn main() -> Int {
  var data = Vec[UInt8].new();
  data.push(0x1F);
  data.push(0x8B);
  var fmt = xiom.compress.detect_format(&data);
  if fmt == "gzip" && xiom.compress.is_compressed(&data) {
    return 0;
  }
  return 1;
}
