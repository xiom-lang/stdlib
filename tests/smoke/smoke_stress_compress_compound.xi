module smoke_stress_compress_compound
use xiom.compress;

fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(67u8); data.push(111u8); data.push(109u8); data.push(112u8);
    data.push(111u8); data.push(117u8); data.push(110u8); data.push(100u8);
    data.push(32u8); data.push(116u8); data.push(101u8); data.push(115u8);
    data.push(116u8); data.push(32u8); data.push(100u8); data.push(97u8);
    data.push(116u8); data.push(97u8); data.push(46u8);

    var is_comp = compress.is_compressed(&data);

    var compressed = compress.gzip_compress(&data);
    match compressed {
      Ok(c) => {
        var is_comp2 = compress.is_compressed(&c);
        var fmt = compress.detect_format(&c);
        var ratio = compress.compression_ratio(data.len(), c.len());

        if is_comp {
          return 1;
        }
        if not is_comp2 {
          return 2;
        }
        if fmt.len() == 0 {
          return 3;
        }
        if ratio < 0.0 {
          return 4;
        }
        return 0;
      }
      Err(_) => { return 1; }
    }
}
