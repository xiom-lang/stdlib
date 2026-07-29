module smoke_stress_compress_gzip_empty
  use xiom.compress;

  fn main() -> Int {
    var data = Vec[UInt8].new();

    var compressed = compress.gzip_compress(&data);

    match compressed {
      Ok(c) => {
        var decompressed = compress.gzip_decompress(&c);
        match decompressed {
          Ok(result) => {
            if result.len() == 0 {
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
