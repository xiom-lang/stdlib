module p_hash_probe
use xiom.io;
use xiom.convert;

interface H2 { fn hash(self, hasher: Hasher2); }
interface Hasher2 { fn write_int(self, n: Int); fn finish(self) -> Int; }
type D2 = { state: Int; }
fn D2.new() -> D2 { return D2{ state: 5381 }; }
fn D2.write_int(self, n: Int) { self.state = self.state * 33 + n; }
fn D2.finish(self) -> Int { return self.state; }

impl H2[Int] {
  fn hash(self, hasher: Hasher2) { hasher.write_int(self); }
}

fn hval[T: H2](v: &T) -> Int {
  var h = D2.new();
  v.hash(h);
  return h.finish();
}

fn main() -> Int {
  var a = hval(42);
  var b = hval(42);
  var c = hval(43);
  io.println("a=" + convert.int_to_string(a) + " b=" + convert.int_to_string(b) + " c=" + convert.int_to_string(c));
  if a != b { return 1; }
  if a == c { return 2; }
  return 0;
}
