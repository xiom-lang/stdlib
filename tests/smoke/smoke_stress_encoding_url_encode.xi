module smoke_stress_encoding_url_encode
use xiom.encoding;

fn main() -> Int {
    var original = "hello world";
    var encoded = encoding.url_encode(original);
    match encoding.url_decode(encoded) {
      Ok(decoded) => {
        if decoded == original {
          return 0;
        }
        return 1;
      }
      Err(_) => { return 1; }
    }
}
