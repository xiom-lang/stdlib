module smoke_stress_rand_random_in_range
use xiom.rand;

fn main() -> Int {
        var r = rand.random();
        if r >= 0.0 {
            if r < 1.0 {
                return 0;
            } else {
                return 2;
            }
        } else {
            return 1;
}
