module smoke_stress_hash_bool
use xiom.hash;

fn main() -> Int {
    var t1 = hash.hash(true);
    var t2 = hash.hash(true);
    var f1 = hash.hash(false);
    if t1 == t2 && t1 != f1 {
      return 0;
    }
    return 1;
}
