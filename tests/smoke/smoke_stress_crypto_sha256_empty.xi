module smoke_stress_crypto_sha256_empty
use xiom.crypto;

fn main() -> Int {
    var data = Vec[UInt8].new();

    var hash = crypto.sha256(&data);

    if hash.len() == 32 {
      return 0;
    }
    return 1;
}
