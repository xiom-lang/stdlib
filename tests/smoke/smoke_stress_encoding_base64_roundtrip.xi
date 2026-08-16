module smoke_stress_encoding_base64_roundtrip
use xiom.encoding;

fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(72u8);
    data.push(101u8);
    data.push(108u8);
    data.push(108u8);
    data.push(111u8);
    var encoded = encoding.base64_encode(&data);
    match encoding.base64_decode(encoded) {
      Ok(decoded) => {
        if decoded.len() == data.len() {
          return 0;
        }
        return 1;
      }
      Err(_) => { return 1; }
    }
}
