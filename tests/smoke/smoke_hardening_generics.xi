// Hardening smoke: generic Float64/Float32 correctness + interface impl
// dispatch + explicit generic type args. Returns 0 on success.
interface Num[T] {
  fn add(a: T, b: T) -> T;
}

impl Num[Int] {
  fn add(a: Int, b: Int) -> Int { return a + b; }
}

impl Num[Float64] {
  fn add(a: Float64, b: Float64) -> Float64 { return a + b; }
}

fn add2[T](a: T, b: T) -> T {
  return a + b;
}

fn main() -> Int {
  // --- generic Int (explicit type args) ---
  var i = add2[Int](20, 22);
  if i != 42 { return 1; }

  // --- generic Float64 (explicit type args) -- was corrupted to i64 ---
  var f = add2[Float64](1.5, 2.25);
  var fe: Float64 = 3.75;
  if f != fe { return 2; }

  // --- generic Float32 (explicit type args) -- was resolved to Int ---
  var g = add2[Float32](1.5 as Float32, 2.25 as Float32);
  var ge: Float32 = 3.75 as Float32;
  if g != ge { return 3; }

  // --- generic inferred from args (no explicit type args) ---
  var h = add2(10, 32);
  if h != 42 { return 4; }

  // --- interface impl dispatch: Int ---
  var a = Num[Int].add(20, 22);
  if a != 42 { return 5; }

  // --- interface impl dispatch: Float64 ---
  var b = Num[Float64].add(1.5, 2.25);
  if b != fe { return 6; }

  // --- interface impl dispatch via direct type method ---
  var c = Int.add(21, 21);
  if c != 42 { return 7; }

  return 0;
}
