module smoke_stress_rand_seed_repro
    use xiom.rand;

    fn main() -> Int {
        var rng1 = rand.StdRng.from_seed(12345);
        var rng2 = rand.StdRng.from_seed(12345);
        var val1 = rng1.sample_uniform(0.0, 100.0);
        var val2 = rng2.sample_uniform(0.0, 100.0);
        if val1 == val2 {
            return 0;
        } else {
            return 1;
        }
    }
}
