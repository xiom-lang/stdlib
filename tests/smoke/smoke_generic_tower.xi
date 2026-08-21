// 3c smoke: generic numeric tower -- ONE generic implementation serves all
// widths via interface impl dispatch. Returns 0 on success.
interface Num[T] {
  fn add(a: T, b: T) -> T;
  fn sub(a: T, b: T) -> T;
  fn mul(a: T, b: T) -> T;
  fn div(a: T, b: T) -> T;
  fn zero() -> T;
  fn one() -> T;
}

impl Num[Int] {
  fn add(a: Int, b: Int) -> Int { return a + b; }
  fn sub(a: Int, b: Int) -> Int { return a - b; }
  fn mul(a: Int, b: Int) -> Int { return a * b; }
  fn div(a: Int, b: Int) -> Int { return a / b; }
  fn zero() -> Int { return 0; }
  fn one() -> Int { return 1; }
}

impl Num[Int32] {
  fn add(a: Int32, b: Int32) -> Int32 { return a + b; }
  fn sub(a: Int32, b: Int32) -> Int32 { return a - b; }
  fn mul(a: Int32, b: Int32) -> Int32 { return a * b; }
  fn div(a: Int32, b: Int32) -> Int32 { return a / b; }
  fn zero() -> Int32 { return 0 as Int32; }
  fn one() -> Int32 { return 1 as Int32; }
}

impl Num[Float64] {
  fn add(a: Float64, b: Float64) -> Float64 { return a + b; }
  fn sub(a: Float64, b: Float64) -> Float64 { return a - b; }
  fn mul(a: Float64, b: Float64) -> Float64 { return a * b; }
  fn div(a: Float64, b: Float64) -> Float64 { return a / b; }
  fn zero() -> Float64 { return 0.0; }
  fn one() -> Float64 { return 1.0; }
}

impl Num[Float32] {
  fn add(a: Float32, b: Float32) -> Float32 { return a + b; }
  fn sub(a: Float32, b: Float32) -> Float32 { return a - b; }
  fn mul(a: Float32, b: Float32) -> Float32 { return a * b; }
  fn div(a: Float32, b: Float32) -> Float32 { return a / b; }
  fn zero() -> Float32 { return 0 as Float32; }
  fn one() -> Float32 { return 1 as Float32; }
}

// Generic lerp over the tower: a*(1-t) + b*t -- one impl, all widths.
fn lerp[T: Num](a: T, b: T, t: T) -> T {
  var one = Num[T].one();
  var omt = Num[T].sub(one, t);
  return Num[T].add(Num[T].mul(a, omt), Num[T].mul(b, t));
}

// Generic average over the tower.
fn average[T: Num](a: T, b: T) -> T {
  var sum = Num[T].add(a, b);
  return Num[T].div(sum, Num[T].one() + Num[T].one());
}

fn main() -> Int {
  // Int
  if lerp[Int](0, 100, 1) != 100 { return 1; }
  if lerp[Int](0, 100, 0) != 0 { return 2; }
  if average[Int](10, 20) != 15 { return 3; }

  // Int32
  if lerp[Int32](0 as Int32, 10 as Int32, 1 as Int32) != (10 as Int32) { return 4; }

  // Float64
  var f = lerp[Float64](0.0, 100.0, 0.5);
  if f != (50.0 as Float64) { return 5; }
  var fa = average[Float64](10.0, 20.0);
  if fa != (15.0 as Float64) { return 6; }

  // Float32
  var g = lerp[Float32](0 as Float32, 100 as Float32, 0.5 as Float32);
  if g != (50 as Float32) { return 7; }

  return 0;
}
