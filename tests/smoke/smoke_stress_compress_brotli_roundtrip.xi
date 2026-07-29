module smoke_stress_compress_brotli_roundtrip
  use xiom.compress;

  fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(72u8); data.push(101u8); data.push(108u8); data.push(108u8); data.push(111u8);

    var c = compress.brotli_compress(&data);
    match c {
      Ok(compressed) => {
        var d = compress.brotli_decompress(&compressed);
        match d {
          Ok(result) => {
            if result.len() == data.len() {
              return 0;
            }
            return 1;
          }
          Err(_) => { return 1; }
        }
      }
      Err(_) => { return 1; }
    }
  }
