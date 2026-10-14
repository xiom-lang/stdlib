// p_wave133_shapes.xi -- wave 133 lock: the sweep-campaign opener --
// core parsers (to_int_from_str / to_float_from_str), the hash family
// (DefaultHasher.write_str / djb2 / sdbm / fnv1_32 / adler32_str), the io
// parsers + path helpers and the buffered-writer copy now read through
// cached raw pointers / the runtime-mirror decode instead of the
// strnlen-per-call runtime accessors. Byte-exact outputs. Returns 0 when
// every case holds.

module p_wave133_shapes

use xiom.string;
use xiom.core;
use xiom.hash;
use xiom.hash.adler as shadler;
use xiom.io;
use xiom.io.buffer as sbuf;

fn mk2(a: Int, b: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  Str::from_utf8(v)
}

fn main() -> Int {
  // ---- core.to_int_from_str ----
  let i1 = core.to_int_from_str("0");
  if !i1.is_ok { return 1; }
  if i1.value != 0 { return 2; }
  let i2 = core.to_int_from_str("-42");
  if !i2.is_ok { return 3; }
  if i2.value != 0 - 42 { return 4; }
  let i3 = core.to_int_from_str("+7");
  if !i3.is_ok { return 5; }
  if i3.value != 7 { return 6; }
  let i4 = core.to_int_from_str("");
  if i4.is_ok { return 7; }
  let i5 = core.to_int_from_str("12a");
  if i5.is_ok { return 8; }
  let i6 = core.to_int_from_str(mk2(0xC3, 0xA9));
  if i6.is_ok { return 9; }

  // ---- core.to_float_from_str ----
  let f1 = core.to_float_from_str("1.5");
  if !f1.is_ok { return 10; }
  if f1.value != 1.5 { return 11; }
  let f2 = core.to_float_from_str("-2.25");
  if !f2.is_ok { return 12; }
  if f2.value != 0.0 - 2.25 { return 13; }
  let f3 = core.to_float_from_str("1e3");
  if !f3.is_ok { return 14; }
  if f3.value != 1000.0 { return 15; }
  let f4 = core.to_float_from_str("1.5e2");
  if !f4.is_ok { return 16; }
  if f4.value != 150.0 { return 17; }
  let f5 = core.to_float_from_str("1.2.3");
  if f5.is_ok { return 18; }

  // ---- hash family ----
  if hash.djb2("") != 5381 { return 19; }
  if hash.sdbm("") != 0 { return 20; }
  if hash.fnv1_32("") != 2166136261 { return 21; }
  let h = hash.DefaultHasher.new();
  h.write_str("abc");
  if h.finish() != hash.djb2("abc") { return 22; }
  if shadler.adler32_str("Wikipedia") != 0x11E60398 { return 23; }
  if shadler.adler32_str("") != 1 { return 24; }

  // ---- io parsers ----
  let p1 = io.parse_int("42");
  if !p1.is_ok { return 25; }
  if p1.value != 42 { return 26; }
  let p2 = io.parse_int("-7");
  if !p2.is_ok { return 27; }
  if p2.value != 0 - 7 { return 28; }
  let p3 = io.parse_int("12a");
  if p3.is_ok { return 29; }
  let p4 = io.parse_float("1.5");
  if !p4.is_ok { return 30; }
  if p4.value != 1.5 { return 31; }
  let p5 = io.parse_float("x");
  if p5.is_ok { return 32; }

  // ---- io path helpers ----
  let pp = io.parent_path("/a/b");
  if !pp.is_some { return 33; }
  if pp.value != "/a" { return 34; }
  let pp2 = io.parent_path("abc");
  if pp2.is_some { return 35; }
  let fn1 = io.file_name("/a/b");
  if !fn1.is_some { return 36; }
  if fn1.value != "b" { return 37; }
  let fn2 = io.file_name("/");
  if fn2.is_some { return 38; }
  let ex1 = io.extension("a.tar.gz");
  if !ex1.is_some { return 39; }
  if ex1.value != "gz" { return 40; }
  let ex2 = io.extension("a");
  if ex2.is_some { return 41; }
  let ex3 = io.extension(".hidden");
  if ex3.is_some { return 42; }

  // ---- buffered writer copy ----
  var w = sbuf.buf_writer_new(1);
  let wr = sbuf.bw_write_str(&mut w, string.str_concat("ab", mk2(0xC3, 0xA9)));
  if !wr.is_ok { return 43; }
  if w.buf.len() != 4 { return 44; }
  let b2 = w.buf[2];
  if b2 != 0xC3 as UInt8 { return 45; }
  let b3 = w.buf[3];
  if b3 != 0xA9 as UInt8 { return 46; }

  return 0;
}
