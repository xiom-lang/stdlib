// p_sync_sizeof.xi -- strict-catalog-gate probe for the xiom.sync intrinsic
// binding (stdlib lane, 2026-09-15). r40 (strict off): compiles with
// "catalog body [xiom.sync]: undefined variable 'size_of'" warnings.
// r41 (strict on): the same findings are HARD ERRORS unless sync.xi imports
// xiom.core.size_of. Exercises the Arc bodies that reference size_of.
module p_sync_sizeof
use xiom.sync;
use xiom.io;

fn main() -> Int {
  var a = sync.Arc.new(42);
  if a.strong_count() != 1 { return 1; };
  if a.get() != 42 { return 2; };
  io.println("P_SYNC_SIZEOF OK");
  io.flush_stdout();
  0
}
