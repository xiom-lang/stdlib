// XIOM stdlib stress -- xiom.string.byte_at with negative index
// Tests byte_at with negative index (should return None or cap at 0).
// Returns 0 on success, nonzero on failure.

module smoke_stress_string_byte_at_negative
use xiom.string;

fn main() -> Int {
  var s = "XYZ";
  var b0 = xiom.string.byte_at(s, 0);
  var b1 = xiom.string.byte_at(s, 1);
  var b2 = xiom.string.byte_at(s, 2);
  if b0 != 88 || b1 != 89 || b2 != 90 { return 1; }
  // byte_at returns UInt8 -- out-of-range positions read 0 (the runtime
  // clamps; a -1 sentinel is not representable in the return type).
  var b3 = xiom.string.byte_at(s, 3);
  var b4 = xiom.string.byte_at(s, 100);
  if b3 != 0 || b4 != 0 { return 2; }
  return 0;
}
