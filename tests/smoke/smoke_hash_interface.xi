module smoke_hash_interface
use xiom.hash;

fn main() -> Int {
  var h = hash.DefaultHasher.new();

  var data = Vec[UInt8].new();
  data.push(10 as UInt8);
  h.write(&data);

  h.write_int(42);

  h.write_str("hello");

  var result = h.finish();
  if result == 5381 { return 1; }

  return 0;
}
