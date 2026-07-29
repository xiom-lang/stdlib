module smoke_stress_encoding_hex_upper
  use xiom.encoding;

  fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(0x4au8);
    data.push(0x5fu8);
    var encoded = encoding.hex_encode_upper(&data);
    if encoded.len() == 4 {
      return 0;
    }
    return 1;
  }
