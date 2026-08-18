module smoke_stress_compress_gzip_large
use xiom.compress;

fn main() -> Int {
    var data = Vec[UInt8].new();
    var i = 0;
    while i < 5000 {
      data.push(65u8);
      i = i + 1;
    }

    var compressed = compress.gzip_compress(&data);

    match compressed {
      Ok(c) => {
        var decompressed = compress.gzip_decompress(&c);
        match decompressed {
          Ok(result) => {
            if result.len() == 5000 {
              return 0;
            }
            return 1;
          }
          Err(_) => { return 1; }
        }
      }
      Err(_) => { return 1; }
    }}
