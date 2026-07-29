module smoke_stress_rand_pick
    use xiom.rand;

    fn main() -> Int {
        var v = vec_of(10, 20, 30);
        var result = rand.pick(v);
        match result {
            Some(x) => {
                return 0;
            },
            None => {
                return 1;
            }
        }
    }
}
