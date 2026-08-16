module smoke_stress_encoding_base64url
use xiom.encoding;

fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(72u8);
    data.push(101u8);
    data.push(108u8);
    data.push(108u8);
    data.push(111u8);
    var encoded = encoding.base64url_encode(&data);
    match encoding.base64url_decode(encoded) {
      Ok(decoded) => {
        if decoded.len() == 5 {
          return 0;
        }
        return 1;
      }
      Err(_) => { return 1; }
    }
}
