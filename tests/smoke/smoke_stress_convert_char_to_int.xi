module smoke_stress_convert_char_to_int
    use xiom.convert;

    fn main() -> Int {
        var result = convert.char_to_int('A');
        if result == 65 {
            return 0;
        } else {
            return 1;
        }
    }
}
