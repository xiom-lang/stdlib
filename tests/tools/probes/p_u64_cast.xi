module p_u64_cast
use xiom.serialize.endian;
use xiom.io;

fn main() -> Int {
  var n: Int = 0 - 2;
  var out = Vec[UInt8].new();
  write_u64_be(&mut out, n as UInt64);
  io.println("be[0]=" + (out[0] as Int) + " be[7]=" + (out[7] as Int) + " len=" + out.len());

  var out2 = Vec[UInt8].new();
  write_u64_le(&mut out2, n as UInt64);
  io.println("le[0]=" + (out2[0] as Int) + " le[7]=" + (out2[7] as Int));

  // Round-trip via read_u64_be / read_u64_le and cast back.
  var r = read_u64_be(out, 0) as Int;
  io.println("round_be=" + r);
  var r2 = read_u64_le(out2, 0) as Int;
  io.println("round_le=" + r2);

  // from_be_bytes semantics for short inputs via raw read path.
  var b2 = Vec[UInt8].new(); b2.push(1); b2.push(2);
  var n9 = Vec[UInt8].new();
  var i = 0; while i < 9 { n9.push(1); i = i + 1; }
  io.println("short2_len=" + b2.len() + " nine_len=" + n9.len());
  return 0;
}
