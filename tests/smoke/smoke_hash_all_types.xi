module smoke_hash_all_types
use xiom.hash;

fn main() -> Int {
  var h_i = hash.hash(42);
  var h_n = hash.hash(-42);
  var h_z = hash.hash(0);

  if h_i == h_n { return 0; }
  if h_i == h_z { return 0; }
  if h_n == h_z { return 0; }

  var h_t = hash.hash(true);
  var h_f = hash.hash(false);
  if h_t == h_f { return 1; }

  return 0;
}
