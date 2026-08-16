module smoke_stress_crypto_blake3_large
use xiom.crypto;

fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(76u8); data.push(111u8); data.push(114u8); data.push(101u8);
    data.push(109u8); data.push(32u8); data.push(105u8); data.push(112u8);
    data.push(115u8); data.push(117u8); data.push(109u8); data.push(32u8);
    data.push(100u8); data.push(111u8); data.push(108u8); data.push(111u8);
    data.push(114u8); data.push(32u8); data.push(115u8); data.push(105u8);
    data.push(116u8); data.push(32u8); data.push(97u8); data.push(109u8);
    data.push(101u8); data.push(116u8); data.push(44u8); data.push(32u8);
    data.push(99u8); data.push(111u8); data.push(110u8); data.push(115u8);
    data.push(101u8); data.push(99u8); data.push(116u8); data.push(101u8);
    data.push(116u8); data.push(117u8); data.push(114u8); data.push(32u8);
    data.push(97u8); data.push(100u8); data.push(105u8); data.push(112u8);
    data.push(105u8); data.push(115u8); data.push(99u8); data.push(105u8);
    data.push(110u8); data.push(103u8); data.push(32u8); data.push(101u8);
    data.push(108u8); data.push(105u8); data.push(116u8); data.push(46u8);
    data.push(32u8); data.push(83u8); data.push(101u8); data.push(100u8);
    data.push(32u8); data.push(100u8); data.push(111u8); data.push(32u8);
    data.push(101u8); data.push(105u8); data.push(117u8); data.push(115u8);
    data.push(109u8); data.push(111u8); data.push(100u8); data.push(32u8);
    data.push(116u8); data.push(101u8); data.push(109u8); data.push(112u8);
    data.push(111u8); data.push(114u8); data.push(32u8); data.push(105u8);
    data.push(110u8); data.push(99u8); data.push(105u8); data.push(100u8);
    data.push(105u8); data.push(100u8); data.push(117u8); data.push(110u8);
    data.push(116u8); data.push(32u8); data.push(117u8); data.push(116u8);
    data.push(32u8); data.push(108u8); data.push(97u8); data.push(98u8);
    data.push(111u8); data.push(114u8); data.push(101u8); data.push(46u8);

    var hash = crypto.blake3(&data);
    if hash.len() == 32 {
      var hash2 = crypto.blake3(&data);
      var idx = 0;
      while idx < hash.len() {
        // element access via indexing (Vec.get is not a language builtin)
        var v1 = hash[idx];
        var v2 = hash2[idx];
        if v1 != v2 { return 2; }
        idx = idx + 1;
      }
      return 0;
    }
    return 1;
}
