module smoke_stress_rand_random_bool
use xiom.rand;

fn main() -> Int {
        var val = rand.random_bool();
        if val == true {
            return 0;
        } else {
            if val == false {
                return 0;
            } else {
                return 1;
            }
        }
}
