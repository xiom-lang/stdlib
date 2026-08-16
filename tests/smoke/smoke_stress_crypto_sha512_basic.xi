module smoke_stress_crypto_sha512_basic
use xiom.crypto;

fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(116u8);
    data.push(101u8);
    data.push(115u8);
    data.push(116u8);

    var hash = crypto.sha512(&data);

    if hash.len() == 64 {
      return 0;
    }
    return 1;
}
