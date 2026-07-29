module smoke_hash_sip
use xiom.hash;

fn main() -> Int {
  var data = Vec[UInt8].new();
  data.push('a' as UInt8);
  data.push('b' as UInt8);
  data.push('c' as UInt8);

  var h = hash.sip_hash(&data);
  if h == 0 { return 1; }

  return 0;
}
