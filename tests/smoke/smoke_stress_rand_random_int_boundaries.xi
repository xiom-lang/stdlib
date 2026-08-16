module smoke_stress_rand_random_int_boundaries
use xiom.rand;

fn main() -> Int {
        var val = rand.random_int(1, 10);
        if val >= 1 {
            if val <= 10 {
                return 0;
            } else {
                return 2;
            }
        } else {
            return 1;
        }
}
