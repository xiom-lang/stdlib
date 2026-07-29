module smoke_stress_convert_roundtrip_int
    use xiom.convert;

    fn main() -> Int {
        var original = 42;
        var as_float = convert.int_to_float(original);
        var back = convert.float_to_int(as_float);
        if back == original {
            return 0;
        } else {
            return 1;
        }
    }
}
