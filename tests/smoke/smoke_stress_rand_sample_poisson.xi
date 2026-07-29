module smoke_stress_rand_sample_poisson
use xiom.rand;

fn main() -> Int {
    var rng = rand.StdRng.from_seed(12345);
    var val = rng.sample_poisson(3.0);
    if val >= 0 {
        return 0;
    } else {
        return 1;
    }
}
