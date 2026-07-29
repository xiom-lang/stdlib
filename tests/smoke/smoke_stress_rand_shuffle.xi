module smoke_stress_rand_shuffle
    use xiom.rand;

    fn main() -> Int {
        var v = vec_of(1, 2, 3, 4, 5);
        rand.shuffle(v);
        var count = length(v);
        if count == 5 {
            return 0;
        } else {
            return 1;
        }
    }
}
