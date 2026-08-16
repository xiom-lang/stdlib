module smoke_stress_rand_weighted_pick
use xiom.rand;

fn main() -> Int {
    var items = Vec[Int].new();
    items.push(10); items.push(20); items.push(30);
    var weights = Vec[Float64].new();
    weights.push(1.0); weights.push(2.0); weights.push(3.0);
    match rand.weighted_pick(&items, &weights) {
        Some(val) => {
            return 0;
        },
        None => {
            return 1;
        }
}
