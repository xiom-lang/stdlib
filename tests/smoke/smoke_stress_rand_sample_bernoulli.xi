module smoke_stress_rand_sample_bernoulli
use xiom.rand;

fn main() -> Int {
    var rng = rand.StdRng.from_seed(12345);
    var val = rng.sample_bernoulli(0.5);
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
