module smoke_stress_rand_sample_normal
use xiom.rand;

fn main() -> Int {
    var val = rand.sample_normal(0.0, 1.0);
    if val > -10.0 {
        if val < 10.0 {
            return 0;
        } else {
            return 2;
        }
    } else {
        return 1;
    }
}
