module smoke_hash_djb2
use xiom.hash;

fn main() -> Int {
  var h = hash.DefaultHasher.new();
  h.write_int(42);
  var result1 = h.finish();

  var h2 = hash.DefaultHasher.new();
  h2.write_int(42);
  var result2 = h2.finish();

  if result1 != result2 { return 1; }

  var h3 = hash.DefaultHasher.new();
  h3.write_int(99);
  var result3 = h3.finish();
  if result1 == result3 { return 2; }

  return 0;
}
