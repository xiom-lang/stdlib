module smoke_stress_compress_detect_format
use xiom.compress;

fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(72u8);
    data.push(101u8);
    data.push(108u8);
    data.push(108u8);
    data.push(111u8);

    var compressed = compress.gzip_compress(&data);

    match compressed {
      Ok(c) => {
        var fmt = compress.detect_format(&c);
        if fmt.len() > 0 {
          return 0;
        }
        return 1;
      }
      Err(_) => { return 1; }
    }
}
