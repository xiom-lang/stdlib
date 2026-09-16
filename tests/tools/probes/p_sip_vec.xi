module p_sip_vec
use xiom.hash.siphash;
use xiom.io;
use xiom.convert;
fn main() -> Int {
  var d0 = Vec[UInt8].new();
  var d1 = Vec[UInt8].new();
  d1.push(97u8);
  var k0: UInt64 = 0x0706050403020100;
  var k1: UInt64 = 0x0f0e0d0c0b0a0908;
  var h0 = siphash.siphash24(&d0, k0, k1);
  var h1 = siphash.siphash24(&d1, k0, k1);
  io.println("sip24('')=" + h0);
  io.println("sip24('a')=" + h1);
  var s0 = siphash.siphash24_zerokey(&d0);
  io.println("zerokey('')=" + s0);
  return 0;
}
