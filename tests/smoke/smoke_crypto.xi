// XIOM stdlib smoke test — xiom.crypto
// SHA-256 known-length + determinism check over a small input.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_crypto
use xiom.crypto;

fn main() -> Int {
  var data = Vec[UInt8].new();
  data.push(104); // 'h'
  data.push(105); // 'i'
  let h1 = xiom.crypto.sha256(&data);
  let h2 = xiom.crypto.sha256(&data);
  if h1.len() != 32 {
    return 1;
  }
  let hex = xiom.crypto.sha256_hex(&data);
  if hex.len() != 64 {
    return 1;
  }
  var i = 0;
  while i < 32 {
    if h1[i] != h2[i] {
      return 1;
    }
    i = i + 1;
  }
  return 0;
}
