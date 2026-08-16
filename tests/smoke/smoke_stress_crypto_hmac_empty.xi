module smoke_stress_crypto_hmac_empty
use xiom.crypto;

fn main() -> Int {
    var key = Vec[UInt8].new();
    var data = Vec[UInt8].new();

    var mac = crypto.hmac_sha256(&key, &data);
    if mac.len() == 32 {
      return 0;
    }
    return 1;
}
