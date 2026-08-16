module smoke_stress_convert_float_to_int
use xiom.convert;

fn main() -> Int {
        var result = convert.float_to_int(3.14);
        if result == 3 {
            return 0;
        } else {
            return 1;
        }
}
