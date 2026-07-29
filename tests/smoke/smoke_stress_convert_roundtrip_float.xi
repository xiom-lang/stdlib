module smoke_stress_convert_roundtrip_float
    use xiom.convert;

    fn main() -> Int {
        var original = 100.0;
        var as_int = convert.float_to_int(original);
        var back = convert.int_to_float(as_int);
        if back == original {
            return 0;
        } else {
            return 1;
        }
    }
}
