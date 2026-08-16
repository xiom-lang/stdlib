module smoke_stress_crypto_sha256_accelerated
use xiom.crypto;

fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(84u8); data.push(104u8); data.push(101u8);
    data.push(32u8); data.push(113u8); data.push(117u8);
    data.push(105u8); data.push(99u8); data.push(107u8);
    data.push(32u8); data.push(98u8); data.push(114u8);
    data.push(111u8); data.push(119u8); data.push(110u8);
    data.push(32u8); data.push(102u8); data.push(111u8);
    data.push(120u8); data.push(32u8); data.push(106u8);
    data.push(117u8); data.push(109u8); data.push(112u8);
    data.push(115u8); data.push(32u8); data.push(111u8);
    data.push(118u8); data.push(101u8); data.push(114u8);
    data.push(32u8); data.push(116u8); data.push(104u8);
    data.push(101u8); data.push(32u8); data.push(108u8);
    data.push(97u8); data.push(122u8); data.push(121u8);
    data.push(32u8); data.push(100u8); data.push(111u8);
    data.push(103u8);

    var h1 = crypto.sha256(&data);
    var h2 = crypto.sha256_accelerated(&data);

    if h1.len() != h2.len() {
      return 1;
    }

    var idx = 0;
    while idx < h1.len() {
      // element access via indexing (Vec.get is not a language builtin)
      var v1 = h1[idx];
      var v2 = h2[idx];
      if v1 != v2 { return 2; }
      idx = idx + 1;
    }

    return 0;
}
