// p_async_read_line_codegen.xi -- minimal probe for the async_read_line
// codegen failure found 2026-09-17 by the single-param untested-surface
// sweep (p_sweep1, never-referenced public fns).
// Expected (correct): compiles; with stdin at EOF it returns Ok("") or Err.
// Observed on compiler main R43 (274184be) and v0.60.0:
//   error: clang failed ... '%tmp15' defined with type
//   '%struct.Tuple__Int__Int' but expected '%struct.Tuple__Int__Bool'
// Ownership: compiler lane -- record with this probe.
module p_async_read_line_codegen
use xiom.async.io;

fn main() -> Int {
  xiom.async.io.async_read_line(0);
  return 0;
}
