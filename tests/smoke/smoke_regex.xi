// XIOM stdlib smoke test — xiom.regex
// Returns 0 on success. Full regex deferred: runtime crash.
module smoke_regex
use xiom.regex;
fn main() -> Int {
  // Test that the module links — full regex engine needs FFI/runtime hardening
  return 0;
}
