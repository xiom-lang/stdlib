module smoke_stress_convert_int_to_string
    use xiom.convert;

    fn main() -> Int {
        var result = convert.int_to_string(42);
        if result == "42" {
            return 0;
        } else {
            return 1;
        }
    }
}
