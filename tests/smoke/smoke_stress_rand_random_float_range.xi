module smoke_stress_rand_random_float_range
use xiom.rand;

fn main() -> Int {
        var val = rand.random_float(5.0, 10.0);
        if val >= 5.0 {
            if val <= 10.0 {
                return 0;
            } else {
                return 2;
            }
        } else {
            return 1;
        }
}
