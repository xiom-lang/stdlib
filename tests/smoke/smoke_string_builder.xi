// smoke_string_builder.xi -- xiom.string.builder
// Locks: append/len/materialize round-trip, int append (sign, zero, min-ish),
// clear-and-reuse, multibyte passthrough. Complements the alloc-heavy
// str_concat path with the amortized builder (audit 5.2).
module smoke_string_builder
use xiom.string.builder;
use xiom.io;
use xiom.convert;

fn main() -> Int {
  var sb = sb_new();
  if sb.len() != 0 { io.println("new:len"); return 1; }

  sb_push_str(&mut sb, "Hello");
  sb_push_str(&mut sb, ", ");
  sb_push_str(&mut sb, "World!");
  if sb.len() != 13 { io.println("len:13"); return 2; }
  var s = sb_to_str(&sb);
  if s != "Hello, World!" { io.println("roundtrip"); return 3; }

  // int appends: positive, negative, zero
  var n = sb_new();
  sb_push_int(&mut n, 0);
  sb_push_str(&mut n, "|");
  sb_push_int(&mut n, -42);
  sb_push_str(&mut n, "|");
  sb_push_int(&mut n, 123456);
  var ns = sb_to_str(&n);
  if ns != "0|-42|123456" { io.println("int:" + ns); return 4; }

  // multibyte passthrough byte-for-byte
  var m = sb_new();
  sb_push_str(&mut m, "a\u{00E9}\u{20AC}");
  if m.len() != 6 { io.println("mb:len"); return 5; }
  var ms = sb_to_str(&m);
  if ms.len() != 6 { io.println("mb:out-len"); return 6; }

  // clear and reuse
  sb_clear(&mut m);
  if m.len() != 0 { io.println("clear:len"); return 7; }
  sb_push_str(&mut m, "again");
  var ag = sb_to_str(&m);
  if ag != "again" { io.println("clear:reuse"); return 8; }

  // empty materialize
  var e = sb_new();
  var es = sb_to_str(&e);
  if es.len() != 0 { io.println("empty:len"); return 9; }

  io.println("OK");
  return 0;
}
