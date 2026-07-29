module smoke_stress_compress_brotli_level
  use xiom.compress;

  fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(84u8); data.push(104u8); data.push(101u8);
    data.push(32u8); data.push(113u8); data.push(117u8);
    data.push(105u8); data.push(99u8); data.push(107u8);
    data.push(32u8); data.push(98u8); data.push(114u8);
    data.push(111u8); data.push(119u8); data.push(110u8);
    data.push(32u8); data.push(102u8); data.push(111u8);
    data.push(120u8);

    var compressed = compress.brotli_compress_level(&data, 5);
    match compressed {
      Ok(c) => {
        var decompressed = compress.brotli_decompress(&c);
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
