module smoke_stress_convert_float_to_int_neg
use xiom.convert;

fn main() -> Int {
        var result = convert.float_to_int(-7.5);
        if result == -7 {
            return 0;
        } else {
            return 1;
        }}
