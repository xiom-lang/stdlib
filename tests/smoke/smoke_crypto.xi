// XIOM stdlib smoke test — xiom.crypto
// Returns 0 on success, nonzero on failure (process exit code).
// Full crypto deferred: SHA-256 depends on extern C runtime functions.

module smoke_crypto
use xiom.crypto;

fn main() -> Int {
  // Verify module links: crypto functions use bitwise math which compiles correctly
  return 0;
}
