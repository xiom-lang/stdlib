// p_str_memcpy3.xi -- isolate: dest pointer arithmetic vs second exec
module p_str_memcpy3
use xiom.io;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn xiom_memcpy_dispatch(dest: *UInt8, src: *UInt8, n: UInt) -> *UInt8;
  fn xiom_byte_at(s: Str, pos: Int) -> UInt8;
}

// D: byte-loop first, then memcpy at buf + len_a.
fn concat_d(a: Str, b: Str) -> Str {
  let len_a = a.len();
  let len_b = b.len();
  let total = len_a + len_b;
  unsafe {
    var buf = malloc(total + 1);
    var i = 0;
    while i < len_a {
      buf[i] = xiom_byte_at(a, i);
      i = i + 1;
    }
    xiom_memcpy_dispatch(buf + len_a, b as *UInt8, len_b as UInt);
    buf[total] = 0;
    return Str.from_cstring(buf);
  }
}

// E: two memcpys, both at buf (second overwrites the start).
fn concat_e(a: Str, b: Str) -> Str {
  let len_a = a.len();
  let len_b = b.len();
  let total = len_a + len_b;
  unsafe {
    var buf = malloc(total + 1);
    xiom_memcpy_dispatch(buf, a as *UInt8, len_a as UInt);
    xiom_memcpy_dispatch(buf, b as *UInt8, len_b as UInt);
    buf[len_b] = 0;
    return Str.from_cstring(buf);
  }
}

// F: memcpy at buf, then memcpy at an Int-cast address (workaround shape).
fn concat_f(a: Str, b: Str) -> Str {
  let len_a = a.len();
  let len_b = b.len();
  let total = len_a + len_b;
  unsafe {
    var buf = malloc(total + 1);
    xiom_memcpy_dispatch(buf, a as *UInt8, len_a as UInt);
    var dst2 = (buf as Int + len_a) as *UInt8;
    xiom_memcpy_dispatch(dst2, b as *UInt8, len_b as UInt);
    buf[total] = 0;
    return Str.from_cstring(buf);
  }
}

fn main() -> Int {
  io.println("D=[" + concat_d("foo", "bar") + "]");
  io.println("E=[" + concat_e("foo", "barbaz") + "]");
  io.println("F=[" + concat_f("foo", "bar") + "]");
  return 0;
}
