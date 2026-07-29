module smoke_stress_compress_snappy_roundtrip
  use xiom.compress;

  fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(83u8); data.push(110u8); data.push(97u8);
    data.push(112u8); data.push(112u8); data.push(121u8);
    data.push(32u8); data.push(105u8); data.push(115u8);
    data.push(32u8); data.push(102u8); data.push(97u8);
    data.push(115u8); data.push(116u8); data.push(46u8);

    var compressed = compress.snappy_compress(&data);
    match compressed {
      Ok(c) => {
        var decompressed = compress.snappy_decompress(&c);
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
