module smoke_stress_rand_sample_exponential
use xiom.rand;

fn main() -> Int {
    var rng = rand.StdRng.from_seed(12345);
    var val = rng.sample_exponential(1.0);
    if val >= 0.0 {
        return 0;
    } else {
        return 1;
    }
}
