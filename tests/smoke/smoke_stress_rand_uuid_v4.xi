module smoke_stress_rand_uuid_v4
use xiom.rand;

fn main() -> Int {
    var id = rand.uuid_v4();
    var len = id.len();
        if len >= 36 {
            return 0;
        } else {
            return 1;
}
