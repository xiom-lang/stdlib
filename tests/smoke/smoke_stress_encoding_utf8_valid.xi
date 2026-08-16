module smoke_stress_encoding_utf8_valid
use xiom.encoding;

fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(104u8);
    data.push(101u8);
    data.push(108u8);
    data.push(108u8);
    data.push(111u8);
    if encoding.utf8_valid(&data) {
      return 0;
    }
    return 1;
}
