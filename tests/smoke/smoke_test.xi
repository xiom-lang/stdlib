// NOTE: link/run smoke only
// XIOM stdlib smoke test — xiom.test
// Uses the framework's own run() harness on a trivially-passing check.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_test
use xiom.test;

fn smoke_check() -> TestResult {
  return assert(true, "smoke");
}

fn main() -> Int {
  return test.run(smoke_check);
}
