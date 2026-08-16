module smoke_stress_crypto_hmac_sha256
use xiom.crypto;

fn main() -> Int {
    var key = Vec[UInt8].new();
    key.push(107u8);
    key.push(101u8);
    key.push(121u8);

    var data = Vec[UInt8].new();
    data.push(100u8);
    data.push(97u8);
    data.push(116u8);
    data.push(97u8);

    var mac = crypto.hmac_sha256(&key, &data);

    if mac.len() == 32 {
      return 0;
    }
    return 1;
}
