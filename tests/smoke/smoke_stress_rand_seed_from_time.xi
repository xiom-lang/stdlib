module smoke_stress_rand_seed_from_time
use xiom.rand;

fn main() -> Int {
    rand.seed_from_time();
    rand.seed_from_value(42);
    var val1 = rand.sample_uniform(0.0, 100.0);
    rand.seed_from_value(42);
    var val2 = rand.sample_uniform(0.0, 100.0);
    if val1 == val2 {
        return 0;
    } else {
        return 1;
    }
}
