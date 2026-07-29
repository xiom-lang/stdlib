module smoke_stress_rand_uuid_v7
    use xiom.rand;

    fn main() -> Int {
        var id = rand.uuid_v7();
        var len = length(id);
        if len >= 36 {
            return 0;
        } else {
            return 1;
        }
    }
}
