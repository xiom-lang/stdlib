module smoke_stress_crypto_hash_known_vector
use xiom.crypto;

fn main() -> Int {
    var data = Vec[UInt8].new();

    var hex = crypto.sha256_hex(&data);

    var expected = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";

    if hex == expected {
      return 0;
    }
    return 1;
}
