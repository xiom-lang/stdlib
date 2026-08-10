// 3c+D4 smoke: math/core generic tower module (use xiom.math.core).
// Returns 0 on success.
use xiom.math;
use xiom.io;
use xiom.convert;

fn main() -> Int {
  // Int
  var l1 = math.core.lerp[Int](0, 100, 1);
  if l1 != 100 { io.println("l1-bad"); return 1; }
  var a1 = math.core.average[Int](10, 20);
  if a1 != 15 { io.println("a1-bad"); return 2; }

  // Float64
  var l2 = math.core.lerp[Float64](0.0, 100.0, 0.5);
  if l2 != (50.0 as Float64) { io.println("l2-bad"); return 3; }
  var a2 = math.core.average[Float64](10.0, 20.0);
  if a2 != (15.0 as Float64) { io.println("a2-bad"); return 4; }

  // Float32
  var l3 = math.core.lerp[Float32](0 as Float32, 100 as Float32, 0.5 as Float32);
  if l3 != (50 as Float32) { io.println("l3-bad"); return 5; }

  // UInt64
  var a4 = math.core.average[UInt64](10 as UInt64, 20 as UInt64);
  if a4 != (15 as UInt64) { io.println("a4-bad"); return 6; }

  // sum over Vec[Int]
  var v = Vec[Int].new();
  v.push(1);
  v.push(2);
  v.push(3);
  var s = math.core.sum[Int](v);
  if s != 6 { io.println("s-bad"); return 7; }

  // product over Vec[Int]
  var p = math.core.product[Int](v);
  if p != 6 { io.println("p-bad"); return 8; }

  // negate + twice
  var n = math.core.negate[Int](42);
  if n != -42 { io.println("n-bad"); return 9; }
  var t = math.core.twice[Int](21);
  if t != 42 { io.println("t-bad"); return 10; }

  return 0;
}
