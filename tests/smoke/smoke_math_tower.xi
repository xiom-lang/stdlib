// 3c+D4 smoke: math/core generic tower module (use xiom.math.tower).
// Returns 0 on success.
use xiom.math;
use xiom.io;
use xiom.convert;

fn main() -> Int {
  // Int
  var l1 = math.tower.lerp[Int](0, 100, 1);
  if l1 != 100 { io.println("l1-bad"); return 1; }
  var a1 = math.tower.average[Int](10, 20);
  if a1 != 15 { io.println("a1-bad"); return 2; }

  // Float64
  var l2 = math.tower.lerp[Float64](0.0, 100.0, 0.5);
  if l2 != (50.0 as Float64) { io.println("l2-bad"); return 3; }
  var a2 = math.tower.average[Float64](10.0, 20.0);
  if a2 != (15.0 as Float64) { io.println("a2-bad"); return 4; }

  // Float32
  var l3 = math.tower.lerp[Float32](0 as Float32, 100 as Float32, 0.5 as Float32);
  if l3 != (50 as Float32) { io.println("l3-bad"); return 5; }

  // UInt64
  var a4 = math.tower.average[UInt64](10 as UInt64, 20 as UInt64);
  if a4 != (15 as UInt64) { io.println("a4-bad"); return 6; }

  // sum over Vec[Int]
  var v = Vec[Int].new();
  v.push(1);
  v.push(2);
  v.push(3);
  var s = math.tower.sum[Int](v);
  if s != 6 { io.println("s-bad"); return 7; }

  // product over Vec[Int]
  var p = math.tower.product[Int](v);
  if p != 6 { io.println("p-bad"); return 8; }

  // negate + twice
  var n = math.tower.negate[Int](42);
  if n != -42 { io.println("n-bad"); return 9; }
  var t = math.tower.twice[Int](21);
  if t != 42 { io.println("t-bad"); return 10; }

  // abs / clamp / min2 / max2 via Real
  var ab = math.tower.abs[Int](-42);
  if ab != 42 { io.println("ab-bad"); return 11; }
  var cl = math.tower.clamp[Int](150, 0, 100);
  if cl != 100 { io.println("cl-bad"); return 12; }
  var cl2 = math.tower.clamp[Int](-5, 0, 100);
  if cl2 != 0 { io.println("cl2-bad"); return 13; }
  var mn = math.tower.min2[Int](3, 7);
  if mn != 3 { io.println("mn-bad"); return 14; }
  var mx = math.tower.max2[Int](3, 7);
  if mx != 7 { io.println("mx-bad"); return 15; }
  var af = math.tower.abs[Float64](-1.5);
  if af != (1.5 as Float64) { io.println("af-bad"); return 16; }
  var cf = math.tower.clamp[Float64](0.5, 0.0, 0.25);
  if cf != (0.25 as Float64) { io.println("cf-bad"); return 17; }

  // of_int via FromInt
  var oi = math.tower.of_int[Float64](7);
  if oi != (7.0 as Float64) { io.println("oi-bad"); return 18; }
  var oi2 = math.tower.of_int[UInt64](9);
  if oi2 != (9 as UInt64) { io.println("oi2-bad"); return 19; }

  return 0;
}

