// XIOM stdlib smoke test — xiom.contracts
// Exercises real coverage/statistics accessors without crashing.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_contracts
use xiom.contracts;

fn main() -> Int {
  let n = xiom.contracts.total_contracts();
  let pct = xiom.contracts.coverage_percentage();
  if n >= 0 && pct >= 0.0 {
    return 0;
  }
  return 1;
}
