module smoke_stress_compress_gzip_bad_input
  use xiom.compress;

  fn main() -> Int {
    var bad = Vec[UInt8].new();
    bad.push(0u8);
    bad.push(1u8);
    bad.push(2u8);

    var result = compress.gzip_decompress(&bad);

    if not result.is_ok() {
      return 0;
    }
    return 1;
  }
}
