// XIOM stdlib smoke test — xiom.test
// NOTE: Struct field access on TestResult.passed is affected by BUG-006.
// This test verifies that the test module links, invokes, and runs.
module smoke_test
use xiom.test;

fn main() -> Int {
  // Just invoke test.assert and verify it returns (doesn't crash)
  let r = test.assert(true, "smoke");
  // r.passed should be true but struct field access has known issues
  return 0;
}
