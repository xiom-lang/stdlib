// p_async_read_line_codegen.xi -- regression lock for
// xiom.async.io.async_read_line (never referenced by any smoke).
// Status 2026-09-17: this isolated call COMPILES on v0.60.0 and R43; it was
// originally suspected by the single-param sweep, but that failure needs the
// 54-module import set (see tools/known_failures/README.md,
// p_sweep_single_param.xi). Kept as a passing lock on the function.
// With stdin at EOF it returns Ok("") or Err.
module p_async_read_line_codegen
use xiom.async.io;

fn main() -> Int {
  xiom.async.io.async_read_line(0);
  return 0;
}
