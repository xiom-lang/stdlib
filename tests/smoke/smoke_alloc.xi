// XIOM stdlib smoke test -- xiom.alloc
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_alloc
use xiom.alloc;

fn main() -> Int {
  var layout = alloc.Layout.new(64);
  if layout.size == 64 && layout.align == 8 {
    return 0;
  }
  return 1;
}
