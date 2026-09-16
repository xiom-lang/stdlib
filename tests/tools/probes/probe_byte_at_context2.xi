// probe_byte_at_context2.xi -- round-20 re-check of the contextual byte_at
// OOB case that stayed gated through r17 (state-dependent bound check after
// case+slicing preambles). GREEN: all byte_at OOB reads return 0.
module probe_byte_at_context2
use xiom.string;
use xiom.io;
use xiom.convert;

fn chk(oob: Int, tag: Str) -> Int {
  var v = string.byte_at("", 999);
  if v != 0 { io.println(tag + ":empty-oob=" + convert.int_to_string(v)); return 1; }
  v = string.byte_at("abc", 3);
  if v != 0 { io.println(tag + ":past-end=" + convert.int_to_string(v)); return 2; }
  v = string.byte_at("abc", -1);
  if v != 0 { io.println(tag + ":neg=" + convert.int_to_string(v)); return 3; }
  return 0;
}

fn main() -> Int {
  // preamble: multibyte case mapping + slicing (the r17-gated shape)
  var mixed = "A\u{00E9}B";
  var lowered = string.str_lower(mixed);
  var up = string.str_upper(lowered);
  var s = "ab\u{00E9}cd";
  var mb = string.str_slice(s, 2, 4);
  var r = chk(0, "post-preamble");
  if r != 0 { return r; }
  var s2 = up + mb;
  var v = string.byte_at(s2, s2.len());
  if v != 0 { io.println("concat-oob=" + convert.int_to_string(v)); return 10; }
  io.println("OK");
  return 0;
}
