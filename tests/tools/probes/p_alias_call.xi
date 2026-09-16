module p_alias_call
use xiom.serialize.endian as sendian;
use xiom.io;

fn main() -> Int {
  var out = Vec[UInt8].new();
  sendian.write_u32_le(&mut out, 0x12345678 as UInt32);
  io.println("alias len=" + out.len() + " b0=" + (out[0] as Int));
  return 0;
}
