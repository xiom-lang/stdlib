// p_b32_encalias: explicit alias only, encoding.base32 (canonical).
module p_b32_encalias
use xiom.encoding.base32 as cvt;
use xiom.io;

fn main() -> Int {
  var v = Vec[UInt8].new();
  v.push(102); v.push(111); v.push(111);
  let b = cvt.base32_encode(&v);
  io.println("alias=" + b);
  if b != "MZXW6===" { return 2; };
  0
}
