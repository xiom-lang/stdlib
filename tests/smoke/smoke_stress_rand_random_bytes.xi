module smoke_stress_rand_random_bytes
use xiom.rand;

fn main() -> Int {
    var bytes = rand.random_bytes(16);
    var count = bytes.len();
        if count == 16 {
            return 0;
        } else {
            return 1;
        }
}
