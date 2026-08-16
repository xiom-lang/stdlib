module smoke_stress_rand_sample_binomial
use xiom.rand;

fn main() -> Int {
    var val = rand.sample_binomial(10, 0.5);
    if val >= 0 {
        if val <= 10 {
            return 0;
        } else {
            return 2;
        }
    } else {
        return 1;
    }
}
