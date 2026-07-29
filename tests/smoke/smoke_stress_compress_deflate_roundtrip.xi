module smoke_stress_compress_deflate_roundtrip
  use xiom.compress;

  fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(72u8);
    data.push(101u8);
    data.push(108u8);
    data.push(108u8);
    data.push(111u8);

    var compressed = compress.deflate_compress(&data);

    match compressed {
      Ok(c) => {
        var decompressed = compress.deflate_decompress(&c);
        match decompressed {
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
}
