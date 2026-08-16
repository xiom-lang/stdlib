module smoke_stress_convert_float_to_int_trunc
use xiom.convert;

fn main() -> Int {
        var result = convert.float_to_int(9.99);
        if result == 9 {
            return 0;
        } else {
            return 1;
        }
}
