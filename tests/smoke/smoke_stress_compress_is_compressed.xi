module smoke_stress_compress_is_compressed
  use xiom.compress;

  fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(72u8);
    data.push(101u8);
    data.push(108u8);
    data.push(108u8);
    data.push(111u8);

    var raw_result = compress.is_compressed(&data);

    var compressed = compress.gzip_compress(&data);

    match compressed {
      Ok(gz) => {
        var gz_result = compress.is_compressed(&gz);
        if gz_result {
          return 0;
        }
        return 1;
      }
      Err(_) => { return 1; }
    }
  }
}
