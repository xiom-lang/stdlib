module smoke_stress_rand_pick
use xiom.rand;

fn main() -> Int {
    var v = Vec[Int].new();
    v.push(10); v.push(20); v.push(30);
    match rand.pick(&v) {
        Some(_) => {
            return 0;
        },
        None => {
            return 1;
        }
    }
}
