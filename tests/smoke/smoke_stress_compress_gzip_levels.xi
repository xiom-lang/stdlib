module smoke_stress_compress_gzip_levels
  use xiom.compress;

  fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(71u8); data.push(122u8); data.push(105u8); data.push(112u8);
    data.push(32u8); data.push(108u8); data.push(101u8); data.push(118u8);
    data.push(101u8); data.push(108u8); data.push(115u8); data.push(32u8);
    data.push(116u8); data.push(101u8); data.push(115u8); data.push(116u8);

    var c0 = compress.gzip_compress_level(&data, 0);
    match c0 {
      Ok(r0) => {
        var c1 = compress.gzip_compress_level(&data, 1);
        match c1 {
          Ok(r1) => {
            var c5 = compress.gzip_compress_level(&data, 5);
            match c5 {
              Ok(r5) => {
                var c9 = compress.gzip_compress_level(&data, 9);
                match c9 {
                  Ok(r9) => {
                    if r0.len() > 0 {
                      if r1.len() > 0 {
                        if r5.len() > 0 {
                          if r9.len() > 0 {
                            return 0;
                          }
                        }
                      }
                    }
                    return 1;
                  }
                  Err(_) => { return 1; }
                }
              }
              Err(_) => { return 1; }
            }
          }
          Err(_) => { return 1; }
        }
      }
      Err(_) => { return 1; }
    }
  }
