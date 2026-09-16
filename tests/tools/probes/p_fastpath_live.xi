// p_fastpath_live.xi -- live probe after the memcpy fast-path re-land:
// chained str_concat (the finding-13 failure mode) + builder materialize.
module p_fastpath_live
use xiom.string;
use xiom.string.builder;
use xiom.io;

fn main() -> Int {
  // Chained self-concat through the re-landed str_concat.
  var s = "";
  var i = 0;
  while i < 8 {
    s = string.str_concat(s, "ab");
    io.println("link" + i + " len=" + s.len() + " val=" + s);
    i = i + 1;
  }
  if s != "abababababababab" { io.println("chain mismatch"); return 1; }

  // Operator form + longer alternating chain.
  var t = "x";
  var j = 0;
  while j < 6 {
    t = t + t;
    j = j + 1;
  }
  if t.len() != 64 { io.println("double len=" + t.len()); return 2; }

  // Builder materialize through the re-landed sb_to_str.
  var sb = Vec[UInt8].new();
  var k = 0;
  while k < 100 {
    builder.sb_push_byte(&sb, 65u8);
    k = k + 1;
  }
  let out = builder.sb_to_str(&sb);
  if out.len() != 100 { io.println("sb len=" + out.len()); return 3; }
  if out != string.str_repeat("A", 100) { io.println("sb mismatch"); return 4; }

  var sb2 = builder.sb_new();
  builder.sb_push_str(&sb2, "hello ");
  builder.sb_push_int(&sb2, 42);
  let out2 = builder.sb_to_str(&sb2);
  if out2 != "hello 42" { io.println("sb2=[" + out2 + "]"); return 5; }

  io.println("FASTPATH LIVE OK");
  return 0;
}
