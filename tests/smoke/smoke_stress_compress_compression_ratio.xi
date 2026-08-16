module smoke_stress_compress_compression_ratio
use xiom.compress;

fn main() -> Int {
    var ratio = compress.compression_ratio(100, 50);

    if ratio >= 0.0 {
      return 0;
    }
    return 1;
  }
}
