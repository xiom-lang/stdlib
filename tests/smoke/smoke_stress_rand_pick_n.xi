module smoke_stress_rand_pick_n
use xiom.rand;

fn main() -> Int {
    var v = vec_of(10, 20, 30, 40, 50);
    var rng = rand.StdRng.from_seed(42);
    var result = rng.pick_n(v, 3);
    match result {
        Some(picked) => {
            if picked.len() == 3 {
                return 0;
            } else {
                return 2;
            }
        },
        None => {
            return 1;
        }
    }
}
