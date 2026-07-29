module smoke_stress_compress_lz4_roundtrip
  use xiom.compress;

  fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(76u8); data.push(90u8); data.push(52u8);
    data.push(32u8); data.push(114u8); data.push(111u8);
    data.push(117u8); data.push(110u8); data.push(100u8);
    data.push(116u8); data.push(114u8); data.push(105u8);
    data.push(112u8);

    var compressed = compress.lz4_compress(&data);
    match compressed {
      Ok(c) => {
        var decompressed = compress.lz4_decompress(&c);
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
