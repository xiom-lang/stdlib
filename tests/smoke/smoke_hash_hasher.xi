module smoke_hash_hasher
use xiom.hash;

fn main() -> Int {
  var h = hash.DefaultHasher.new();

  var bytes = Vec[UInt8].new();
  bytes.push(1 as UInt8);
  bytes.push(2 as UInt8);
  bytes.push(3 as UInt8);
  h.write(bytes);

  var result = h.finish();
  if result == 5381 { return 1; }

  return 0;
}
