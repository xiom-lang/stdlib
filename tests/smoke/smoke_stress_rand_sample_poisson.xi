module smoke_stress_rand_sample_poisson
use xiom.rand;

fn main() -> Int {
    var val = rand.sample_poisson(3.0);
    if val >= 0 {
        return 0;
    } else {
        return 1;
    }
}
