module smoke_stress_rand_weighted_pick
use xiom.rand;

fn main() -> Int {
    var items = vec_of(10, 20, 30);
    var weights = vec_of(1.0, 2.0, 3.0);
    var rng = rand.StdRng.from_seed(42);
    var result = rng.weighted_pick(items, weights);
    match result {
        Some(val) => {
            return 0;
        },
        None => {
            return 1;
        }
    }
}
