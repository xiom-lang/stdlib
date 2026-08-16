module smoke_stress_rand_pick_n
use xiom.rand;

fn main() -> Int {
    var v = Vec[Int].new();
    v.push(10); v.push(20); v.push(30); v.push(40); v.push(50);
    var picked = rand.pick_n(&v, 3);
    if picked.len() == 3 {
        return 0;
    } else {
        return 2;
    }
}
